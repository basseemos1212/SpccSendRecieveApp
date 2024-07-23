import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:secret_contact/data/repo/file_repository.dart';
import 'package:secret_contact/data/repo/user_repository.dart';
import 'package:secret_contact/firebase_options.dart';
import 'package:secret_contact/presentation/blocs/chat_bloc.dart';
import 'package:secret_contact/presentation/blocs/file_archeive_bloc/file_archieve_bloc.dart';
import 'package:secret_contact/presentation/blocs/task_bloc/task_assignment_bloc.dart';
import 'package:secret_contact/presentation/pages/category_screen.dart';
import 'package:secret_contact/presentation/pages/chat_screen.dart';
import 'package:secret_contact/presentation/pages/file_archieve_screen.dart';
import 'package:secret_contact/presentation/pages/task_assignment_screen.dart';
import 'package:secret_contact/presentation/pages/task_screen.dart';
import 'package:secret_contact/presentation/pages/task_submission_screen.dart';
import 'package:secret_contact/presentation/widgets/splash_screen.dart';
import 'data/providers/firebase_auth_provider.dart';
import 'domain/usecases/sign_in_usecase.dart';
import 'domain/usecases/upload_file_usecase.dart';
import 'presentation/blocs/auth_bloc/auth_bloc.dart';
import 'presentation/blocs/file_upload_bloc/file_upload_bloc.dart';
import 'presentation/pages/login_screen.dart';
import 'presentation/pages/file_upload_screen.dart';
import 'data/providers/dropbox_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dropboxProvider = DropboxProvider();
    final fileRepository = FileRepository(
      FirebaseStorage.instance,
      FirebaseFirestore.instance,
    );
    final uploadFileUseCase = UploadFileUseCase(fileRepository);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) =>
              AuthBloc(SignInUseCase(UserRepository(FirebaseAuthProvider()))),
        ),
        BlocProvider<FileUploadBloc>(
          create: (_) => FileUploadBloc(uploadFileUseCase),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(dropboxProvider),
        ),
        BlocProvider<TaskAssignmentBloc>(
          create: (context) => TaskAssignmentBloc(),
        ),
        BlocProvider<FileArchiveBloc>(
          create: (context) => FileArchiveBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/categories': (context) => CategoriesScreen(),
          '/secretary-home': (context) => FileUploadScreen(),
          '/chat': (context) => ChatScreen(),
          '/taskAssignment': (context) => TaskAssignmentScreen(),
          '/fileArchive': (context) => FileArchiveScreen(),
          '/tasks': (context) => TasksScreen(),
          '/taskSubmission': (context) => TaskSubmissionScreen()
        },
        locale: const Locale('ar'),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
