import 'package:flutter/material.dart';
import 'hex_colors.dart';

Color gradientColor = HexColor('0F1D27');
Color gradientColor2 = HexColor('020608');
Color whiteColor = HexColor('FFFFFF');
Color darkBlueColor = HexColor('11222D');

Color darkColor = HexColor('152530');
Color liteBlueColor = HexColor('2A2EEC').withOpacity(0.40);
Color blueColor = HexColor('2A2EEC');
Color transparentColor = Colors.transparent;
Color dialogBGColor = HexColor('42424').withOpacity(0.8);
Color greyColor = HexColor('CFCFCF');

Color bgColor = HexColor('525252').withOpacity(0.2);
Color greyLightColor = HexColor('CFCFCF');
Color grey7DColor = HexColor('7D7D7D');

Color blackLiteColor = HexColor('2C2C2C').withOpacity(0.12);
Color inactiveColor = HexColor('2A2A2A');
Color blackColor = HexColor('000000');
Color redColor = HexColor('FF001F');

Color lightBlueColor = HexColor("EFF7FF") ;
Color lightBlue2Color = HexColor("D8E6F3") ;

LinearGradient finalBGGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    gradientColor,
    gradientColor2,
  ],
);