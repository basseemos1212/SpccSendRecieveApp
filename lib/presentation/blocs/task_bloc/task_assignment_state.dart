import 'package:cloud_firestore/cloud_firestore.dart';

abstract class TaskAssignmentState {}

class TaskAssignmentInitial extends TaskAssignmentState {}

class TaskAssignmentLoading extends TaskAssignmentState {}

class TaskAssignmentLoaded extends TaskAssignmentState {
  final List<DocumentSnapshot> users;

  TaskAssignmentLoaded(this.users);
}

class TaskAssignmentSuccess extends TaskAssignmentState {}

class TaskAssignmentError extends TaskAssignmentState {
  final String message;

  TaskAssignmentError(this.message);
}
