using System;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using System.Windows.Shapes;

namespace JAPROJ
{
    public partial class MainWindow : Window
    {
        private BitmapSource loadedBitmap;

        [DllImport("JADll.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern void ASM_AVGFILTER(IntPtr pixelData, int width, int startY, int endY, int imageHeight);

        [DllImport("CPPDll.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern void AVGFILTER(IntPtr pixelData, int width, int startY, int endY, int imageHeight);

        public MainWindow()
        {
            InitializeComponent();
        }

        private void OnLoadImageClick(object sender, RoutedEventArgs e)
        {
            OpenFileDialog openFileDialog = new OpenFileDialog
            {
                Filter = "Image Files (*.png;*.jpg;*.jpeg;*.bmp)|*.png;*.jpg;*.jpeg;*.bmp",
                Title = "Select an Image"
            };

            if (openFileDialog.ShowDialog() == true)
            {
                SetImage(openFileDialog.FileName);
            }
        }

        private void SetImage(string filePath)
        {
            try
            {
                BitmapImage bitmapImage = new BitmapImage();
                bitmapImage.BeginInit();
                bitmapImage.UriSource = new Uri(filePath, UriKind.Absolute);
                bitmapImage.CacheOption = BitmapCacheOption.OnLoad;
                bitmapImage.EndInit();

                FormatConvertedBitmap rgbBitmap = new FormatConvertedBitmap(bitmapImage, PixelFormats.Rgb24, null, 0);
                loadedBitmap = rgbBitmap;

                OriginalImage.Source = loadedBitmap;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading image: {ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private int[][] CalculateHistogram(BitmapSource bitmap)
        {
            int width = bitmap.PixelWidth;
            int height = bitmap.PixelHeight;
            int bytesPerPixel = 3;

            int[][] histogram = new int[3][] { new int[256], new int[256], new int[256] };

            byte[] pixelData = new byte[width * height * bytesPerPixel];
            bitmap.CopyPixels(pixelData, width * bytesPerPixel, 0);

            for (int i = 0; i < pixelData.Length; i += bytesPerPixel)
            {
                histogram[0][pixelData[i]]++;     // Blue channel
                histogram[1][pixelData[i + 1]]++; // Green channel
                histogram[2][pixelData[i + 2]]++; // Red channel
            }

            return histogram;
        }

        private void DrawHistogram(Canvas canvas, int[][] histogram)
        {
            canvas.Children.Clear();

            int maxCount = Math.Max(histogram[0].Max(), Math.Max(histogram[1].Max(), histogram[2].Max()));

            for (int i = 0; i < 256; i++)
            {
                double scale = canvas.Height / maxCount;

                Rectangle blueRect = new Rectangle
                {
                    Width = 1,
                    Height = histogram[0][i] * scale,
                    Fill = Brushes.Blue
                };
                Canvas.SetLeft(blueRect, i);
                Canvas.SetBottom(blueRect, 0);
                canvas.Children.Add(blueRect);

                Rectangle greenRect = new Rectangle
                {
                    Width = 1,
                    Height = histogram[1][i] * scale,
                    Fill = Brushes.Green
                };
                Canvas.SetLeft(greenRect, i);
                Canvas.SetBottom(greenRect, 0);
                canvas.Children.Add(greenRect);

                Rectangle redRect = new Rectangle
                {
                    Width = 1,
                    Height = histogram[2][i] * scale,
                    Fill = Brushes.Red
                };
                Canvas.SetLeft(redRect, i);
                Canvas.SetBottom(redRect, 0);
                canvas.Children.Add(redRect);
            }
        }

        private void OnFilterClick(object sender, RoutedEventArgs e)
        {
            if (loadedBitmap == null)
            {
                MessageBox.Show("Please load an image before filtering.", "Error", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            int[][] histogramBefore = CalculateHistogram(loadedBitmap);
            DrawHistogram(HistogramBefore, histogramBefore);

            if (ThreadCount.SelectedItem is ComboBoxItem threadItem &&
                int.TryParse(threadItem.Content.ToString(), out int numThreads) &&
                numThreads > 0)
            {
                ApplyFilter(numThreads);

                WriteableBitmap filteredBitmap = (WriteableBitmap)FilteredImage.Source;
                int[][] histogramAfter = CalculateHistogram(filteredBitmap);
                DrawHistogram(HistogramAfter, histogramAfter);
            }
            else
            {
                MessageBox.Show("Please select a valid thread count.", "Error", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
        }

        private void ApplyFilter(int numThreads)
        {
            int height = loadedBitmap.PixelHeight;
            int width = loadedBitmap.PixelWidth;
            int bytesPerPixel = 3;

            WriteableBitmap filteredBitmap = new WriteableBitmap(loadedBitmap);

            filteredBitmap.Lock();
            try
            {
                int length = width * height * bytesPerPixel;
                byte[] pixelData = new byte[length];
                IntPtr pBackBuffer = filteredBitmap.BackBuffer;
                Marshal.Copy(pBackBuffer, pixelData, 0, length);

                GCHandle handle = GCHandle.Alloc(pixelData, GCHandleType.Pinned);
                IntPtr pixelDataPtr = Marshal.UnsafeAddrOfPinnedArrayElement(pixelData, 0);

                int baseSegmentHeight = height / numThreads;
                int extraRows = height % numThreads;

                int[] startYs = new int[numThreads];
                int[] endYs = new int[numThreads];

                int currentStartY = 0;
                for (int i = 0; i < numThreads; i++)
                {
                    int segmentHeight = baseSegmentHeight + (i < extraRows ? 1 : 0);
                    startYs[i] = currentStartY;
                    endYs[i] = currentStartY + segmentHeight;
                    currentStartY += segmentHeight;
                }

                bool useCPP = LanguageSelection.SelectedItem is ComboBoxItem langItem && langItem.Content.ToString() == "C++";

                Stopwatch stopwatch = Stopwatch.StartNew();

                Parallel.For(0, numThreads, i =>
                {
                    if (useCPP)
                    {
                        AVGFILTER(pixelDataPtr, width, startYs[i], endYs[i], height);
                    }
                    else
                    {
                        ASM_AVGFILTER(pixelDataPtr, width, startYs[i], endYs[i], height);
                    }
                });

                Marshal.Copy(pixelData, 0, pBackBuffer, length);
                stopwatch.Stop();

                MessageBox.Show($"Filtering completed in {stopwatch.Elapsed.TotalMilliseconds} ms", "Info", MessageBoxButton.OK, MessageBoxImage.Information);
                handle.Free();
            }
            finally
            {
                filteredBitmap.Unlock();
            }

            FilteredImage.Source = filteredBitmap;
        }
    }
}