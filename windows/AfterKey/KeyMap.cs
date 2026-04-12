namespace AfterKey;

public static class KeyMap
{
    private static readonly Dictionary<int, string> Special = new()
    {
        [0x08] = "⌫", [0x09] = "⇥", [0x0D] = "↵", [0x1B] = "ESC", [0x20] = "␣",
        [0x21] = "PGUP", [0x22] = "PGDN", [0x23] = "END", [0x24] = "HOME",
        [0x25] = "←", [0x26] = "↑", [0x27] = "→", [0x28] = "↓",
        [0x2C] = "PRTSC", [0x2D] = "INS", [0x2E] = "DEL",
        [0x14] = "CAPS", [0x90] = "NUMLK", [0x91] = "SCRLK", [0x13] = "PAUSE",
    };

    private static readonly Dictionary<int, string> Punctuation = new()
    {
        [0xBA] = ";", [0xBB] = "=", [0xBC] = ",", [0xBD] = "-",
        [0xBE] = ".", [0xBF] = "/", [0xC0] = "`",
        [0xDB] = "[", [0xDC] = "\\", [0xDD] = "]", [0xDE] = "'",
    };

    private static readonly HashSet<int> Modifiers =
        [0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0x5B, 0x5C];

    static KeyMap()
    {
        for (var i = 0; i < 12; i++)
            Special[0x70 + i] = $"F{i + 1}";
    }

    public static bool IsModifier(int vk) => Modifiers.Contains(vk);

    public static string? GetName(int vk) =>
        Special.GetValueOrDefault(vk)
        ?? Punctuation.GetValueOrDefault(vk)
        ?? (vk is >= 0x30 and <= 0x39 ? ((char)vk).ToString() : null)
        ?? (vk is >= 0x41 and <= 0x5A ? ((char)vk).ToString() : null);
}
