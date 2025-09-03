import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../util/app_strings.dart';
import '../../util/colors.dart';
import '../../util/images.dart';


class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPage();
}

class _SupportPage extends State<SupportPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          AppStrings.support,
          style: TextStyle(color: AppColors.primaryText),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16.0),
              // Text: Hot Line
              const Text(
                'Hot Line',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              // Row: Call Icon and Text
              GestureDetector(
                onTap: () => _makePhoneCall('+8801334260543'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/phone_call.png',
                      width: 25.0,
                      height: 25.0,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      '+880 1334-260543',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
              GestureDetector(
                onTap: () => _makePhoneCall('+8809647260543'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/phone_call.png',
                      width: 25.0,
                      height: 25.0,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      '+880 9647-260543',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Call Icon (Asset Image)
              const SizedBox(height: 20.0),
              // Row: Fb asset image and Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fb asset image
                  Image.asset(
                    'assets/icons/facebook.png',
                    width: 24.0,
                    height: 24.0,
                  ),
                  const SizedBox(width: 8.0),
                  // Text: Facebook Page
                  const Text(
                    'Facebook Page',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
              // Button: Send Message for fb....
              GestureDetector(
                onTap: () {
                  launchUrlString('https://facebook.com/bdtaxationofficial');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      child: Container(
                        height: 40,
                        width: 250,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF003277),
                              Color(0xFF002AE8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(
                                  0, 3), // changes the position of shadow
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'SEND MESSAGE',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              // Row: Whatsapp asset image and Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Whatsapp asset image
                  Image.asset(
                    'assets/icons/whatsapp.png',
                    width: 24.0,
                    height: 24.0,
                  ),
                  const SizedBox(width: 8.0),
                  // Text: Online Support
                  const Text(
                    'Online Support',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
              // SizedBox(height: 16.0),

              // Button: Send Message
              GestureDetector(
                onTap: () async {
                  String url =
                      'https://api.whatsapp.com/send?phone=8801334260543&text=Hello';
                  launchUrlString(url);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      child: Container(
                        height: 40,
                        width: 250,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF00492F),
                              Color(0xFF00A667),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(
                                  0, 3), // changes the position of shadow
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'SEND MESSAGE',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),
              // Text: Corporate Office (bold)
              const Text(
                'Corporate Office',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              // Text: House: 25/2, Lake Circus Road Kalabagan, Dhaka 1205
              const Text(
                'House-119-120, Road-2, Block-CHA, Mirpur-2, Dhaka',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(
                height: 50,
              ),
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16),
                        child: const Text('Developed By'),
                      ),
                    ),
                    const SizedBox(
                      // height: 32,
                      width: 90,
                      child: Image(
                        image: AssetImage(Images.companyLogo),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                child: const Center(
                    child: Text(
                      'App version: 1.0.0',
                      style: TextStyle(fontSize: 16),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // function for calling feature
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }
}