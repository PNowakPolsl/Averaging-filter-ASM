using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using System.Windows.Controls;
using System.Drawing;


namespace JAPROJ
{
    public partial class MainWindow : Window
    {
        private BitmapSource loadedBitmap;

        [DllImport("C:\\Users\\nowak\\OneDrive\\Pulpit\\Piotrek STUDIA\\SEMESTR 5\\JA PROJ\\JAPROJ\\x64\\Debug\\CPPDLL.dll", CallingConvention = CallingConvention.StdCall)]
        // public static extern int nazwa(int a, int b); 
        public static extern void AVGFILTER(IntPtr pixelData, IntPtr outputData, int width, int startY, int endY, int imageHeight);

        private BitmapSource originalBitmap;
        private BitmapSource filteredBitmap;

        public MainWindow()
        {
            InitializeComponent();
        }

        private void OnLoadImageClick(object sender, RoutedEventArgs e)
        {
            OpenFileDialog openFileDialog = new OpenFileDialog
            {
                Filter = "Image Files (*.png;*.jpg;*.jpeg;*.bmp)|*.png;*.jpg;*.jpeg;*.bmp"
            };

            if (openFileDialog.ShowDialog() == true)
            {
                SetImage(openFileDialog.FileName);
            }
        }

        private void OnFilterClick(object sender, RoutedEventArgs e)
        {
            if (loadedBitmap == null)
            {
                MessageBox.Show("Proszę załadować obraz.", "Błąd", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            if (int.TryParse((ThreadCount.SelectedItem as ComboBoxItem)?.Content.ToString(), out int numThreads) && numThreads > 0)
            {
                ApplyFilter(numThreads);
            }
            else
            {
                MessageBox.Show("Proszę wybrać liczbę wątków.", "Błąd", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void ApplyFilter(int numThreads)
        {
            int width = loadedBitmap.PixelWidth;
            int height = loadedBitmap.PixelHeight;
            int bytesPerPixel = 3; // RGB format
            int stride = width * bytesPerPixel;

            // Tworzenie WriteableBitmap dla wynikowego obrazu
            WriteableBitmap filteredBitmap = new WriteableBitmap(loadedBitmap);

            // Bufory dla pikseli wejściowych i wyjściowych
            byte[] pixelData = new byte[stride * height];
            byte[] outputData = new byte[stride * height];

            // Kopiowanie pikseli do tablicy wejściowej
            loadedBitmap.CopyPixels(pixelData, stride, 0);

            // Przypięcie tablicy do pamięci
            GCHandle pixelHandle = GCHandle.Alloc(pixelData, GCHandleType.Pinned);
            GCHandle outputHandle = GCHandle.Alloc(outputData, GCHandleType.Pinned);

            IntPtr pixelPtr = Marshal.UnsafeAddrOfPinnedArrayElement(pixelData, 0);
            IntPtr outputPtr = Marshal.UnsafeAddrOfPinnedArrayElement(outputData, 0);

            // Dzielimy obraz na segmenty w pionie
            int segmentHeight = height / numThreads;
            int extraRows = height % numThreads;

            Stopwatch stopwatch = Stopwatch.StartNew();

            Parallel.For(0, numThreads, i =>
            {
                int startY = i * segmentHeight;
                int endY = startY + segmentHeight + (i == numThreads - 1 ? extraRows : 0);

                AVGFILTER(pixelPtr, outputPtr, width, startY, endY, height);
            });

            stopwatch.Stop();

            // Kopiowanie wyników do WriteableBitmap
            filteredBitmap.Lock();
            Marshal.Copy(outputData, 0, filteredBitmap.BackBuffer, outputData.Length);
            filteredBitmap.AddDirtyRect(new Int32Rect(0, 0, width, height));
            filteredBitmap.Unlock();

            // Zwolnienie pamięci
            pixelHandle.Free();
            outputHandle.Free();

            // Ustawienie przefiltrowanego obrazu
            FilteredImage.Source = filteredBitmap;

            MessageBox.Show($"Czas przetwarzania: {stopwatch.ElapsedMilliseconds} ms", "Przetwarzanie zakończone", MessageBoxButton.OK, MessageBoxImage.Information);
        }


        private void SetImage(string filePath)
        {
            try
            {
                BitmapImage bitmap = new BitmapImage();
                bitmap.BeginInit();
                bitmap.UriSource = new Uri(filePath, UriKind.Absolute);
                bitmap.CacheOption = BitmapCacheOption.OnLoad;
                bitmap.EndInit();

                FormatConvertedBitmap formattedBitmap = new FormatConvertedBitmap(bitmap, PixelFormats.Rgb24, null, 0);
                loadedBitmap = formattedBitmap;

                OriginalImage.Source = loadedBitmap;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Błąd ładowania obrazu: {ex.Message}", "Błąd", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}