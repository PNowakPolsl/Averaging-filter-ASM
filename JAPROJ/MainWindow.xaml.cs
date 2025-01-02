using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace JAPROJ
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        [DllImport("C:\\Users\\nowak\\OneDrive\\Pulpit\\Piotrek STUDIA\\SEMESTR 5\\JA PROJ\\JAPROJ\\x64\\Debug\\CPPDLL.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern int nazwa(int a, int b); 
        
       // [DllImport("C:\\Users\\nowak\\OneDrive\\Pulpit\\Piotrek STUDIA\\SEMESTR 5\\JA PROJ\\JAPROJ\\x64\\Debug\\JADLL.dll", CallingConvention = CallingConvention.StdCall)]
        //public static extern int MyProc1(int a, int b);
        public MainWindow()
        {
            InitializeComponent();
            
            Debug.WriteLine(nazwa(2, 2));
           // Debug.WriteLine(MyProc1(2, 3));
        }
    }
}