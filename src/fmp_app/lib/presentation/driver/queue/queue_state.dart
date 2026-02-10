enum QueueOfferStatus {
  none,
  offered,
  accepted,
  skipped,
  timedOut,
}

class QueueState {
  QueueOfferStatus status;
  int secondsLeft;

  QueueState({
    required this.status,
    this.secondsLeft = 15,
  });
}
