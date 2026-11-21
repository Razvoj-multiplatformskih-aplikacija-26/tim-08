import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EventActionFeedback extends StatelessWidget {
  const EventActionFeedback({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<DogadjajBloc, DogadjajState>(
        listenWhen: (_, state) => state is DogadjajiError && state.nakonIzmene,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((state as DogadjajiError).poruka)),
          );
        },
        child: child,
      );
}
