import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../resource/color_constant.dart';
import '../../resource/font.dart';


extension ValiationExtensions on String {
  String? requiredValidation(value) {
    if (isEmpty) {
      return '$value is required';
    }
    return null;
  }

  String? messageValidation() {
    if (isEmpty) {
      return 'Please enter message';
    }
    return null;
  }


  String? subjectValidation() {
    if (isEmpty) {
      return 'Please enter SubjectLine';
    }
    return null;
  }

  validateUser() {
    if (isEmpty) {
      return 'Name is required';
    } else {
      return null;
    }
  }

  validate1Mobile() {
    if (replaceAll(" ", "").isEmpty) {
      return 'Mobile Number is required';
    }
    return null;
  }

  validateMobile() {
    var regExp = RegExp(mobilePattern);
    if (replaceAll(" ", "").isEmpty) {
      return 'Mobile Number is required';
    } else if (replaceAll(" ", "").length != 10) {
      return 'Mobile number must 10 digits';
    } else if (!regExp.hasMatch(replaceAll(" ", ""))) {
      return 'Mobile number must be digits';
    }
    return null;
  }

  validateEmail() {
    var regExp = RegExp(emailPattern);
    if (isEmpty) {
      return 'Email is required';
    } else if (!regExp.hasMatch(this)) {
      return 'Invalid email';
    } else {
      return null;
    }
  }

  validateUserName() {
    RegExp regExp = RegExp(userNamePattern);
    if (isEmpty) {
      return 'Please enter UserName';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid UserName';
    }
    return null;
  }

  validateLink() {
    RegExp regExp = RegExp(urlPattern);
    if (isEmpty) {
      return 'Please enter Link';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid Link';
    }
    return null;
  }

  validateAddress() {
    if (isEmpty) {
      return 'Address is required';
    } else {
      return null;
    }
  }

  validateBio() {
    if (isEmpty) {
      return 'Bio is required';
    } else {
      return null;
    }
  }

  validateDesignation() {
    if (isEmpty) {
      return 'Designation is required';
    } else {
      return null;
    }
  }


  validateCompanyName() {
    if (isEmpty) {
      return 'Company Name is required';
    } else {
      return null;
    }
  }

  validateCompanyMobile() {
    var regExp = RegExp(mobilePattern);
    if (replaceAll(" ", "").isEmpty) {
      return 'Company Number is required';
    } else if (replaceAll(" ", "").length != 10) {
      return 'Mobile number must 10 digits';
    } else if (!regExp.hasMatch(replaceAll(" ", ""))) {
      return 'Mobile number must be digits';
    }
    return null;
  }

  validateCompanyEmail() {
    var regExp = RegExp(emailPattern);
    if (isEmpty) {
      return 'Company Email is required';
    } else if (!regExp.hasMatch(this)) {
      return 'Invalid email';
    } else {
      return null;
    }
  }

  validateCompanyDetail() {
    if (isEmpty) {
      return 'Company Detail is required';
    } else {
      return null;
    }
  }

  validateCompanyAddress() {
    if (isEmpty) {
      return 'Company Address is required';
    } else {
      return null;
    }
  }

  validateCompanyWebsite() {
    if (isEmpty) {
      return 'Company Website is required';
    } else {
      return null;
    }
  }

  validateCompanyLinkedin() {
    RegExp regExp = RegExp(urlPattern);
    if (isEmpty) {
      return 'Company Review Url is required';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid Link';
    }
    return null;
  }

  validateVideoLink() {
    RegExp regExp = RegExp(urlPattern);
    if (isEmpty) {
      return 'Video Url is required';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid Link';
    }
    return null;
  }


  validateCompanyReview() {
    RegExp regExp = RegExp(urlPattern);
    if (isEmpty) {
      return 'Company Review Url is required';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid Link';
    }
    return null;
  }

  validateCompanyPaymentLink() {
    if (isEmpty) {
      return 'Payment UPI is required';
    } else {
      return null;
    }
  }


  String? validateInstagram() {
    RegExp regExp = RegExp(urlPattern);
    if (isEmpty) {
      return 'Instagram Link is required';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid Link';
    }
    return null;
  }

  String? validateFacebook() {
    RegExp regExp = RegExp(urlPattern);
    if (isEmpty) {
      return 'Facebook Link is required';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid Link';
    }
    return null;
  }

  String? validateTweeter() {
    RegExp regExp = RegExp(urlPattern);
    if (isEmpty) {
      return 'Tweeter Link is required';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid Link';
    }
    return null;
  }

  String? validateYoutube() {
    RegExp regExp = RegExp(urlPattern);
    if (isEmpty) {
      return 'Youtube Link is required';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid Link';
    }
    return null;
  }

  String? validateLinkedin() {
    RegExp regExp = RegExp(urlPattern);
    if (isEmpty) {
      return 'Linkedin Link is required';
    }
    else if (!regExp.hasMatch(this)) {
      return 'Please enter valid Link';
    }
    return null;
  }

}

extension WidgetExtensions on Widget {
  circleProgressIndicator() => Container(
      alignment: FractionalOffset.center,
      child: const CircularProgressIndicator(strokeWidth: 1));

  myText(
      { required String title,
        Color textColor = Colors.white,
        FontWeight fontWeight = FontWeight.normal,
        double titleSize = 18}) =>
      Text(
        title,
        style: TextStyle(
            color: textColor, fontSize: titleSize, fontWeight: fontWeight),
      );

 Widget inputField({
    ValueChanged<String>? onChanged,
    TextEditingController? controller,
    TextCapitalization textCapitalization =  TextCapitalization.none,
    double? height,
    double? width,
    int? maxLength,
    TextInputType? keyboardType,
    String? hintText,
    String? labelText,
    int? maxLines,
    int? minLines,
    bool obscureText = false,
   Widget? suffixIcon,
    Widget? icon,
    FormFieldValidator<String>? validation,
    bool? editable,
    bool readonly = false,
   String? suffixText,
    TextInputAction? textInputAction,
   List<TextInputFormatter>? inputFormatters,
    Color? borderColor,

  }) =>

      TextFormField(
        textCapitalization: textCapitalization,
        style: TextStyle(fontFamily:regularFont,color: whiteColor,fontSize: 15),
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        readOnly: readonly,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        // style: TextStyle(color: loginBox),
        maxLines: maxLines,
        minLines: minLines,
        onChanged: onChanged,
        enabled: editable,

        decoration: InputDecoration(
          counterText: "",
          labelText: labelText,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor ?? greyColor),
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
          hintStyle: TextStyle(fontFamily:regularFont,color: greyColor,fontSize: 15),
          focusedBorder: OutlineInputBorder(
            borderSide:  BorderSide(color: blueColor),
            borderRadius: BorderRadius.circular(16.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(16.0),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: greyColor),
            borderRadius: BorderRadius.circular(16.0),
          ),
          enabledBorder:OutlineInputBorder(
            borderSide: BorderSide(color: greyColor),
            borderRadius: BorderRadius.circular(16.0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(16.0),
          ),
          hintText: hintText,
          prefixIcon:  icon,
          suffixIcon: suffixIcon,
          suffixText: suffixText,
          suffixStyle: TextStyle(fontFamily:regularFont,color: whiteColor,fontSize: 15),
          errorStyle:  const TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
          errorMaxLines: 2,
        ),
        validator: validation,
      );
}

textFormFieldWidget({
  ValueChanged<String>? onChanged,
  TextEditingController? controller,
  TextCapitalization textCapitalization =  TextCapitalization.none,
  double? height,
  double? width,
  int? maxLength,
  TextInputType? keyboardType,
  String? hintText,
  String? labelText,
  int? maxLines,
  int? minLines,
  bool obscureText = false,
  InkWell? inkWell,
  Widget? icon,
  FormFieldValidator<String>? validation,
  bool? editable,
  bool readonly = false,
  TextInputAction? textInputAction,
  Color? borderColor,}) {
  return TextFormField(
    style: TextStyle(fontFamily:regularFont,color: whiteColor,fontSize: 15),
    textInputAction: textInputAction,
    readOnly: readonly,
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    maxLength: maxLength,
    // style: TextStyle(color: loginBox),
    maxLines: maxLines,
    minLines: minLines,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: greyColor),
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
      hintStyle: TextStyle(fontFamily:regularFont,color: whiteColor,fontSize: 15),
      focusedBorder: OutlineInputBorder(
        borderSide:  BorderSide(color: blueColor),
        borderRadius: BorderRadius.circular(16.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(16.0),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: greyColor),
        borderRadius: BorderRadius.circular(16.0),
      ),
      enabledBorder:OutlineInputBorder(
        borderSide: BorderSide(color: greyColor),
        borderRadius: BorderRadius.circular(16.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),
    validator: validation,
  );
}


var emailPattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
var mobilePattern = r'(^[0-9]*$)';
String urlPattern = r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';
String userNamePattern = r'^\\S*$';
