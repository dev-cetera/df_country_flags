import 'package:flutter/material.dart';
import 'package:df_country_flags/df_country_flags.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: CountryFlagBuilder(
          countryCode: CountryCode.VIERKLEUR,
          builder: (context, byteData) {
            return SvgPicture.memory(byteData);
          },
        ),
      ),
    );
  }
}
