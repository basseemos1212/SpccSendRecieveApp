import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_assignment_event.dart';
import 'task_assignment_state.dart';

class TaskAssignmentBloc
    extends Bloc<TaskAssignmentEvent, TaskAssignmentState> {
  TaskAssignmentBloc() : super(TaskAssignmentInitial());

  Stream<TaskAssignmentState> mapEventToState(
      TaskAssignmentEvent event) async* {
    if (event is LoadUsersEvent) {
      yield* _mapLoadUsersEventToState();
    } else if (event is AssignTaskEvent) {
      yield* _mapAssignTaskEventToState(event);
    }
  }

  Stream<TaskAssignmentState> _mapLoadUsersEventToState() async* {
    yield TaskAssignmentLoading();
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      yield TaskAssignmentLoaded(snapshot.docs);
    } catch (e) {
      yield TaskAssignmentError('Failed to load users');
    }
  }

  Stream<TaskAssignmentState> _mapAssignTaskEventToState(
      AssignTaskEvent event) async* {
    try {
      // Add the task to the user's tasks
      await FirebaseFirestore.instance.collection('tasks').add({
        'userEmail': event.user['email'],
        'task': event.task,
        'deadline': event.deadline,
        'summary': event.summary,
        'assignedBy': FirebaseAuth.instance.currentUser!.email,
        'assignedAt': Timestamp.now(),
      });

      // Add a notification for the user
      String notificationText =
          'تم توكيل ملف ${event.summary}\nإلى ${event.user['name']}';
      await FirebaseFirestore.instance.collection('notifications').add({
        'text': notificationText,
        'fileUrl': '',
        'read': false,
        'timestamp': Timestamp.now(),
      });

      yield TaskAssignmentSuccess();
    } catch (e) {
      yield TaskAssignmentError('Failed to assign task');
    }
  }
}
