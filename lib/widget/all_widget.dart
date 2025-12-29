import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../resource/color_constant.dart';
import '../../resource/font.dart';

AppBar appBarWidget(title) {
  return AppBar(
    backgroundColor: gradientColor,
    centerTitle: true,
    elevation: 4,
    title: whiteSemiBoldTextWidget(title, 20),
  );
}

// Container decoration
BoxDecoration containerDecoration({
  Color? colorBorder,
  Color? color,
  BorderRadiusGeometry? borderRadius,
  double? width,
  List<BoxShadow>? boxShadow,
}) {
  return BoxDecoration(
    border: Border.all(width: width ?? 0, color: colorBorder ?? blackLiteColor),
    borderRadius: borderRadius ?? BorderRadius.circular(15),
    color:  color ?? inactiveColor,
    boxShadow: boxShadow,
  );
}

dividerWidget({Color? color}){
  return Divider(color: color ?? Colors.black12);
}

sizedBoxHWidget(double size) {
  return SizedBox(height: size);
}

sizedBoxWWidget(double size) {
  return SizedBox(width: size);
}
Widget whiteTextWidget(String text, double fs, {TextAlign? textAlign, double? wordSpacing, bool? softWrap, TextOverflow? overflow, int? maxLines}) {
  return Text(text,
    style:
    TextStyle(fontSize: fs, color: whiteColor, fontFamily: regularFont, wordSpacing: wordSpacing),
    textAlign: textAlign ?? TextAlign.center,
    maxLines: maxLines ?? 4,
  );
}

Widget whiteEBoldTextWidget(String text, double fs, {TextAlign? textAlign, bool? softWrap, TextOverflow? overflow, int? maxLines}) {
  return Text(
    text,
    style: TextStyle(fontSize: fs, color: whiteColor, fontFamily: extraBold),
    textAlign: textAlign ?? TextAlign.center,
    softWrap: softWrap,
    overflow: overflow,
    maxLines: maxLines ?? 2,
  );
}

Widget whiteSemiBoldTextWidget(String text, double fs, {Color? color, TextAlign? textAlign, bool? softWrap, TextOverflow? overflow, int? maxLines}) {
  return Text(
    text,
    style: TextStyle(color: color ?? whiteColor, fontSize: fs, fontFamily: semiBold),
    textAlign: textAlign ?? TextAlign.center,
    softWrap: softWrap,
    overflow: overflow,
    maxLines: maxLines ?? 2,
  );
}

Widget greyTextWidget(String text, double fs, {TextAlign? textAlign, double? wordSpacing, bool? softWrap, TextOverflow? overflow, int? maxLines}) {
  return Text(text,
    style:
    TextStyle(fontSize: fs, color:  Colors.grey.shade400, fontFamily: regularFont, wordSpacing: wordSpacing),
    textAlign: textAlign ?? TextAlign.center,
    maxLines: maxLines ?? 4,
  );
}

Widget greySemiBoldTextWidget(String text, double fs, {TextAlign? textAlign, bool? softWrap, TextOverflow? overflow, int? maxLines}) {
  return Text(
    text,
    style: TextStyle(color: greyColor, fontSize: fs, fontFamily: semiBold),
    textAlign: textAlign ?? TextAlign.center,
    softWrap: softWrap,
    overflow: overflow,
    maxLines: maxLines ?? 2,
  );
}


Widget greyMTextWidget(String text, double fs, {TextAlign? textAlign}) {
  return Text(
    text,
    style: TextStyle(color: greyColor, fontSize: fs, fontFamily: mediumFont),
    textAlign: textAlign ?? TextAlign.center,
    maxLines: 2,
  );
}

Widget greyMLightTextWidget(String text, double fs, {TextAlign? textAlign}) {
  return Text(
    text,
    style: TextStyle(color: greyLightColor, fontSize: fs, fontFamily: mediumItalic),
    textAlign: textAlign ?? TextAlign.center,
    maxLines: 2,
  );
}

Widget greyRightTextWidget(String text, double fs, {TextAlign? textAlign}) {
  return Text(
    text,
    style: TextStyle(color: greyLightColor, fontSize: fs, fontFamily: regularFont),
    textAlign: textAlign ?? TextAlign.center,
    maxLines: 2,
  );
}

Widget blueTextWidget(String text, double fs, {TextAlign? textAlign, double? wordSpacing, bool? softWrap, TextOverflow? overflow, int? maxLines}) {
  return Text(text,
    style:
    TextStyle(fontSize: fs, color: blueColor, fontFamily: regularFont, wordSpacing: wordSpacing),
    textAlign: textAlign ?? TextAlign.center,
    maxLines: 4,
  );
}

Widget blueSemiBoldTextWidget(String text, double fs, {TextAlign? textAlign, double? wordSpacing, bool? softWrap, TextOverflow? overflow, int? maxLines}) {
  return Text(text,
    style:
    TextStyle(fontSize: fs, color: blueColor, fontFamily: semiBold, wordSpacing: wordSpacing),
    textAlign: textAlign ?? TextAlign.center,
    maxLines: 4,
  );
}

Widget blackTextWidget(String text, double fs, {TextAlign? textAlign, double? wordSpacing, bool? softWrap, TextOverflow? overflow, int? maxLines}) {
  return Text(text,
    style:
    TextStyle(fontSize: fs, color: blackColor, fontFamily: regularFont, wordSpacing: wordSpacing),
    textAlign: textAlign ?? TextAlign.center,
    maxLines: 4,
  );
}

Widget blackSemiBoldTextWidget(String text, double fs, {TextAlign? textAlign, bool? softWrap, TextOverflow? overflow, int? maxLines}) {
  return Text(
    text,
    style: TextStyle(color: blackColor, fontSize: fs, fontFamily: semiBold),
    textAlign: textAlign ?? TextAlign.center,
    softWrap: softWrap,
    overflow: overflow,
    maxLines: maxLines ?? 2,
  );
}

Widget appButton(
    {VoidCallback? onPressed,
      String? title,
      double? width,
      double? height,
      double? radius,
      double? fSize,
      Gradient? bgColor,
      BorderRadiusGeometry? borderRadius,
      WidgetStateProperty<Color?>? backgroundColor,
      Color? color}) {
  return InkWell(
    onTap: onPressed,
    child: Container(
      height: height ?? Get.width / 6.5,
      width: width ?? Get.width / 2,
      decoration: BoxDecoration(
        color: color ?? blueColor,
        borderRadius: borderRadius ?? BorderRadius.circular(15),
      ),
      child: Center(child: whiteSemiBoldTextWidget(title ?? "", fSize ?? 18)),
    ),
  );
}

Widget appOutlineButton(
    {VoidCallback? onPressed,
      String? title,
      double? width,
      double? height,
      double? radius,
      double? fSize,
      Gradient? bgColor,
      BorderRadiusGeometry? borderRadius,
      WidgetStateProperty<Color?>? backgroundColor,
      Color? color,
      Color? colorBorder,}) {
  return InkWell(
    onTap: onPressed,
    child: Container(
      padding: EdgeInsets.zero,
      height: height ?? Get.width / 7,
      width: width ?? Get.width / 2.3,
      decoration: BoxDecoration(
        color: color ?? transparentColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: colorBorder ?? blueColor),
      ),
      child: Center(child: whiteSemiBoldTextWidget(title ?? "", fSize ?? 16)),
    ),
  );
}

// Toggle switch
Widget toggleButtonWidget({required bool value, void Function(bool)? onChanged}){
  return CupertinoSwitch(
    activeTrackColor: blueColor,
    value: value,
    inactiveTrackColor: inactiveColor,
    onChanged: onChanged,
  );
}