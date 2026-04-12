using System.ComponentModel;
using System.IO;
using System.Runtime.CompilerServices;
using System.Text.Json;

namespace AfterKey;

public sealed class AppSettings : INotifyPropertyChanged
{
    private static readonly string Dir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "AfterKey");

    private static readonly string FilePath = Path.Combine(Dir, "settings.json");

    public static AppSettings Instance { get; } = Load();

    public event PropertyChangedEventHandler? PropertyChanged;

    private double _displayDuration = 3.0;
    private int _maxKeys = 5;
    private string _position = "bottom_right";
    private bool _showModifiers = true;
    private int _fontSize = 32;
    private int _cornerRadius = 12;
    private double _borderWidth = 1.0;
    private string _bgColor = "#000000";
    private double _bgOpacity = 0.3;
    private string _textColor = "#FFFFFF";
    private double _textOpacity = 1.0;
    private string _borderColor = "#FFFFFF";
    private double _borderOpacity = 0.2;

    public double DisplayDuration { get => _displayDuration; set => Set(ref _displayDuration, value); }
    public int MaxKeys { get => _maxKeys; set => Set(ref _maxKeys, value); }
    public string Position { get => _position; set => Set(ref _position, value); }
    public bool ShowModifiers { get => _showModifiers; set => Set(ref _showModifiers, value); }
    public int FontSize { get => _fontSize; set => Set(ref _fontSize, value); }
    public int CornerRadius { get => _cornerRadius; set => Set(ref _cornerRadius, value); }
    public double BorderWidth { get => _borderWidth; set => Set(ref _borderWidth, value); }
    public string BgColor { get => _bgColor; set => Set(ref _bgColor, value); }
    public double BgOpacity { get => _bgOpacity; set => Set(ref _bgOpacity, value); }
    public string TextColor { get => _textColor; set => Set(ref _textColor, value); }
    public double TextOpacity { get => _textOpacity; set => Set(ref _textOpacity, value); }
    public string BorderColor { get => _borderColor; set => Set(ref _borderColor, value); }
    public double BorderOpacity { get => _borderOpacity; set => Set(ref _borderOpacity, value); }

    public void Reset()
    {
        var fresh = new AppSettings();
        DisplayDuration = fresh.DisplayDuration;
        MaxKeys = fresh.MaxKeys;
        Position = fresh.Position;
        ShowModifiers = fresh.ShowModifiers;
        FontSize = fresh.FontSize;
        CornerRadius = fresh.CornerRadius;
        BorderWidth = fresh.BorderWidth;
        BgColor = fresh.BgColor;
        BgOpacity = fresh.BgOpacity;
        TextColor = fresh.TextColor;
        TextOpacity = fresh.TextOpacity;
        BorderColor = fresh.BorderColor;
        BorderOpacity = fresh.BorderOpacity;
    }

    private void Set<T>(ref T field, T value, [CallerMemberName] string? name = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return;
        field = value;
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        Save();
    }

    private void Save()
    {
        Directory.CreateDirectory(Dir);
        var json = JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(FilePath, json);
    }

    private static AppSettings Load()
    {
        if (!File.Exists(FilePath)) return new AppSettings();
        try
        {
            var json = File.ReadAllText(FilePath);
            return JsonSerializer.Deserialize<AppSettings>(json) ?? new AppSettings();
        }
        catch { return new AppSettings(); }
    }
}
