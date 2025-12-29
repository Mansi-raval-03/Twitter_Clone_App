class ServerString {
  const ServerString._();

  // API
  static String baseURL = 'https://api.alphaconnect.co.in/v1/';
  static String loginUrl = '${baseURL}auth/register-or-login';
  static String updateUserInfoUrl = '${baseURL}users/user-profile';
  static String getProfileUrl = '${baseURL}users/user-profile';
  static String coverImageUrl = '${baseURL}users/user-cover-image';
  static String addUserCompanyUrl = '${baseURL}users/user-company';
  static String addSocialMediaUrl = '${baseURL}users/user-social-media';
  static String updateSocialMediaUrl = '${baseURL}users/update-social-media';
  static String deleteSocialMediaUrl = '${baseURL}users/user-social-media';
  static String uploadDigitalCardUrl = '${baseURL}users/upload-digital-card';
  static String uploadGalleryUrl = '${baseURL}users/user-gallery';
  static String addProductDetailUrl = '${baseURL}users/user-product';
  static String updateProductDetailUrl = '${baseURL}users/update-product';
  static String addTestimonialUrl = '${baseURL}users/user-testimonial';
  static String addBrochureUrl = '${baseURL}users/user-files';
  static String addOfficeTimingUrl = '${baseURL}users/user-office-timing';
  static String getThemesUrl = '${baseURL}users/get-themes';
  static String addThemesUrl = '${baseURL}users/set-theme';
  static String addVideoUrl = '${baseURL}users/user-video-link';
  static String getEnquiryUrl = '${baseURL}users/user-inquiries';
  static String enquiryStatusUrl = '${baseURL}users/user-inquiry-status';


}
