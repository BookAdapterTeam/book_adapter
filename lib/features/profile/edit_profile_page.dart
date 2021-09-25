// Handles Profile edit action

import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/profile/profile.dart';
import 'package:book_adapter/widget/appbar_widget.dart';
import 'package:book_adapter/widget/button_widget.dart';
import 'package:book_adapter/widget/profile_widget.dart';
import 'package:book_adapter/widget/textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditProfileView extends ConsumerWidget {
  const EditProfileView({Key? key}) : super(key: key);

  static const routeName = '${ProfileView.routeName}/editProfile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(firebaseControllerProvider).currentUser!;
    return Scaffold(
      appBar: buildAppBar(context, 'Edit Profile'),
      body: ListView(
        
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          if (user.photoURL != null) ... [
            ProfileWidget(
              imagePath: user.photoURL!,
              isEdit: true, 
              onClicked: () async {}
            ),
            const SizedBox(height: 24),
          ],

          
          TextFieldWidget(
            label: 'Full Name', 
            text: user.displayName ?? '', 
            onChanged: (name) {},
          ),
          const SizedBox(height: 24),

          // TODO: Add change email function. Will need to ask for current password.
          // TextFieldWidget(
          //   label: 'Email', 
          //   text: user.email ?? 'Signed in anonymously', 
          //   onChanged: (email) {
          //     // TODO: Save email in controller
          //   },
          // ), 
          Center(child: submitButton())
        ],
      )
    );    
  }

  Widget submitButton() => ButtonWidget(
    text: 'Submit',
    onClicked: () {
      // TODO: Change email if it is different
    },
  );
}
