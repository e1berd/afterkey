using System.Collections.ObjectModel;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Threading;

namespace AfterKey;

public partial class OverlayWindow : Window
{
    private const int GWL_EXSTYLE = -20;
    private const int WS_EX_TRANSPARENT = 0x00000020;
    private const int WS_EX_TOOLWINDOW = 0x00000080;

    public ObservableCollection<KeyBubbleVM> Keys { get; } = [];

    private readonly DispatcherTimer _timer;

    public OverlayWindow()
    {
        InitializeComponent();
        KeysPanel.ItemsSource = Keys;

        _timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(100) };
        _timer.Tick += (_, _) => Cleanup();
        _timer.Start();

        AppSettings.Instance.PropertyChanged += (_, _) => UpdateLayout();
        UpdateLayout();
    }

    protected override void OnSourceInitialized(EventArgs e)
    {
        base.OnSourceInitialized(e);
        var hwnd = new WindowInteropHelper(this).Handle;
        var style = GetWindowLong(hwnd, GWL_EXSTYLE);
        SetWindowLong(hwnd, GWL_EXSTYLE, style | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW);
    }

    public void AddKey(string text)
    {
        Dispatcher.Invoke(() =>
        {
            var s = AppSettings.Instance;
            Keys.Add(new KeyBubbleVM(text, DateTime.UtcNow.AddSeconds(s.DisplayDuration), s));

            while (Keys.Count > s.MaxKeys)
                Keys.RemoveAt(0);
        });
    }

    private void Cleanup()
    {
        var now = DateTime.UtcNow;
        for (var i = Keys.Count - 1; i >= 0; i--)
            if (Keys[i].Expire < now)
                Keys.RemoveAt(i);
    }

    private new void UpdateLayout()
    {
        var s = AppSettings.Instance;
        var pos = s.Position;

        KeysPanel.HorizontalAlignment = pos switch
        {
            _ when pos.Contains("left") => HorizontalAlignment.Left,
            _ when pos.Contains("right") => HorizontalAlignment.Right,
            _ => HorizontalAlignment.Center,
        };

        KeysPanel.VerticalAlignment = pos switch
        {
            _ when pos.Contains("top") => VerticalAlignment.Top,
            _ when pos.Contains("bottom") => VerticalAlignment.Bottom,
            _ => VerticalAlignment.Center,
        };

        KeysPanel.Margin = new Thickness(50);
    }

    [DllImport("user32.dll")] private static extern int GetWindowLong(IntPtr hwnd, int index);
    [DllImport("user32.dll")] private static extern int SetWindowLong(IntPtr hwnd, int index, int newStyle);
}

public record KeyBubbleVM
{
    public string Text { get; }
    public DateTime Expire { get; }
    public double FontSize { get; }
    public CornerRadius CornerRadius { get; }
    public Thickness BorderThickness { get; }
    public Brush BorderBrush { get; }
    public Brush Background { get; }
    public Brush Foreground { get; }

    public KeyBubbleVM(string text, DateTime expire, AppSettings s)
    {
        Text = text;
        Expire = expire;
        FontSize = s.FontSize;
        CornerRadius = new CornerRadius(s.CornerRadius);
        BorderThickness = new Thickness(s.BorderWidth);

        var bg = (Color)ColorConverter.ConvertFromString(s.BgColor);
        bg.A = (byte)(s.BgOpacity * 255);
        Background = new SolidColorBrush(bg);

        var tc = (Color)ColorConverter.ConvertFromString(s.TextColor);
        tc.A = (byte)(s.TextOpacity * 255);
        Foreground = new SolidColorBrush(tc);

        var bc = (Color)ColorConverter.ConvertFromString(s.BorderColor);
        bc.A = (byte)(s.BorderOpacity * 255);
        BorderBrush = new SolidColorBrush(bc);
    }
}
