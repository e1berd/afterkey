using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using Forms = System.Windows.Forms;

namespace AfterKey;

public partial class SettingsWindow : Window
{
    private readonly AppSettings _s = AppSettings.Instance;
    private bool _loading = true;

    public SettingsWindow()
    {
        InitializeComponent();
        LoadValues();
        _loading = false;
    }

    private void LoadValues()
    {
        DurationSlider.Value = _s.DisplayDuration;
        DurationLabel.Text = _s.DisplayDuration.ToString("F1");
        MaxKeysSlider.Value = _s.MaxKeys;
        MaxKeysLabel.Text = _s.MaxKeys.ToString();
        ShowModifiersCheck.IsChecked = _s.ShowModifiers;

        FontSizeSlider.Value = _s.FontSize;
        FontSizeLabel.Text = _s.FontSize.ToString();
        CornerRadiusSlider.Value = _s.CornerRadius;
        CornerRadiusLabel.Text = _s.CornerRadius.ToString();
        BorderWidthSlider.Value = _s.BorderWidth;
        BorderWidthLabel.Text = _s.BorderWidth.ToString("F1");

        BgOpacitySlider.Value = _s.BgOpacity;
        BgOpacityLabel.Text = _s.BgOpacity.ToString("F2");
        TextOpacitySlider.Value = _s.TextOpacity;
        TextOpacityLabel.Text = _s.TextOpacity.ToString("F2");
        BorderOpacitySlider.Value = _s.BorderOpacity;
        BorderOpacityLabel.Text = _s.BorderOpacity.ToString("F2");

        SetButtonColor(BgColorBtn, _s.BgColor);
        SetButtonColor(TextColorBtn, _s.TextColor);
        SetButtonColor(BorderColorBtn, _s.BorderColor);
    }

    private void OnDurationChanged(object s, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        _s.DisplayDuration = e.NewValue;
        DurationLabel.Text = e.NewValue.ToString("F1");
    }

    private void OnMaxKeysChanged(object s, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        _s.MaxKeys = (int)e.NewValue;
        MaxKeysLabel.Text = ((int)e.NewValue).ToString();
    }

    private void OnShowModifiersChanged(object s, RoutedEventArgs e) =>
        _s.ShowModifiers = ShowModifiersCheck.IsChecked == true;

    private void OnFontSizeChanged(object s, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        _s.FontSize = (int)e.NewValue;
        FontSizeLabel.Text = ((int)e.NewValue).ToString();
    }

    private void OnCornerRadiusChanged(object s, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        _s.CornerRadius = (int)e.NewValue;
        CornerRadiusLabel.Text = ((int)e.NewValue).ToString();
    }

    private void OnBorderWidthChanged(object s, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        _s.BorderWidth = e.NewValue;
        BorderWidthLabel.Text = e.NewValue.ToString("F1");
    }

    private void OnBgOpacityChanged(object s, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        _s.BgOpacity = e.NewValue;
        BgOpacityLabel.Text = e.NewValue.ToString("F2");
    }

    private void OnTextOpacityChanged(object s, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        _s.TextOpacity = e.NewValue;
        TextOpacityLabel.Text = e.NewValue.ToString("F2");
    }

    private void OnBorderOpacityChanged(object s, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_loading) return;
        _s.BorderOpacity = e.NewValue;
        BorderOpacityLabel.Text = e.NewValue.ToString("F2");
    }

    private void OnPickBgColor(object s, RoutedEventArgs e) =>
        PickColor(c => { _s.BgColor = c; SetButtonColor(BgColorBtn, c); });

    private void OnPickTextColor(object s, RoutedEventArgs e) =>
        PickColor(c => { _s.TextColor = c; SetButtonColor(TextColorBtn, c); });

    private void OnPickBorderColor(object s, RoutedEventArgs e) =>
        PickColor(c => { _s.BorderColor = c; SetButtonColor(BorderColorBtn, c); });

    private void OnPositionClick(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string pos)
            _s.Position = pos;
    }

    private void OnReset(object s, RoutedEventArgs e)
    {
        _s.Reset();
        _loading = true;
        LoadValues();
        _loading = false;
    }

    private static void PickColor(Action<string> apply)
    {
        var dlg = new Forms.ColorDialog { FullOpen = true };
        if (dlg.ShowDialog() != Forms.DialogResult.OK) return;
        var c = dlg.Color;
        apply($"#{c.R:X2}{c.G:X2}{c.B:X2}");
    }

    private static void SetButtonColor(Button btn, string hex)
    {
        var color = (Color)ColorConverter.ConvertFromString(hex);
        btn.Background = new SolidColorBrush(color);
    }
}
