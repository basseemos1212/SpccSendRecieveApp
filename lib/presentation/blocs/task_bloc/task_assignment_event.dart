import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

abstract class TaskAssignmentEvent extends Equatable {
  const TaskAssignmentEvent();

  @override
  List<Object> get props => [];
}

class LoadUsersEvent extends TaskAssignmentEvent {}

class AssignTaskEvent extends TaskAssignmentEvent {
  final DocumentSnapshot user;
  final String task;
  final String deadline;
  final String summary;

  AssignTaskEvent(this.user, this.task,
      {required this.deadline, required this.summary});

  @override
  List<Object> get props => [user, task, deadline, summary];
}
