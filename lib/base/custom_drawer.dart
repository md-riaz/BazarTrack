import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/util/images.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../features/drawer_pages/support_page.dart';
import '../util/app_strings.dart';
import '../util/colors.dart';


class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        backgroundColor: AppColors.background,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1)
              ),
              child: Image.asset(
                Images.logo, height: 10,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.primary,),
              title: Text(AppStrings.shareApp),
              onTap: () {
                SharePlus.instance.share(ShareParams(text: AppStrings.playStoreLink));
              },
            ),
            ListTile(
              onTap: () {
                Get.to(() => const SupportPage(),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 250));
              },
              leading: const Icon(Icons.support,color: AppColors.primary),
              title: Text(AppStrings.support),
            ),
            ListTile(
              leading: const Icon(Icons.info_outlined,color: AppColors.primary),
              title: Text(AppStrings.aboutUs),
              // onTap: () {
              //   Get.to(() => AboutUsPage(),
              //       transition: Transition.rightToLeft,
              //       duration: const Duration(milliseconds: 250));
              // },
            ),
            ListTile(
              leading: const Icon(Icons.perm_device_information,color: AppColors.primary),
              title: Text(AppStrings.appInfo),
              // onTap: () {
              //   Get.to(() => const AppInfoScreen(),
              //       transition: Transition.rightToLeft,
              //       duration: const Duration(milliseconds: 250));
              // },
            ),
            ListTile(
              leading: const Icon(Icons.description,color: AppColors.primary),
              title: Text(AppStrings.termsOfServices),
              // onTap: () {
              //   Get.to(() => TermsOfServicesPage(),
              //       transition: Transition.rightToLeft,
              //       duration: const Duration(milliseconds: 250));
              // },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip,color: AppColors.primary),
              title: Text(AppStrings.privacyPolicy.tr),
              // onTap: () {
              //   Get.to(() => PrivacyPolicyPage(),
              //       transition: Transition.rightToLeft,
              //       duration: const Duration(milliseconds: 250));
              // },
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
              child: Text(
                '${AppStrings.appVersion.tr}: 1.0.0',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(
              height: 50,
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.s,
                children: [
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16),
                      child: Text(
                        AppStrings.developedBy,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .3,
                    child: Image(
                      image: AssetImage(Images.companyLogo),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}