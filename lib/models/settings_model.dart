class Settings
{
  double defaultFontSize;
  bool showChords;
  int primaryColor;
  bool titleUpperCase;
  double titleFontSize;
  bool screenOn;
  bool showCategory;

  Settings(double _defaultFontSize, bool _showChords, int _primaryColor, bool _titleUpperCase, double _titleFontSize, bool _screenOn, bool _showCategory) {
    this.defaultFontSize = _defaultFontSize ?? 20.0;
    this.showChords = _showChords ?? false;
    this.primaryColor = _primaryColor ?? 4280391411;
    this.titleUpperCase = _titleUpperCase ?? false;
    this.titleFontSize = _titleFontSize ?? 24.0;
    this.screenOn = _screenOn ?? false;
    this.showCategory  = _showCategory ?? true;
  }
}

Settings settings;