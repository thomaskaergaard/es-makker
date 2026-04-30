import 'bid.dart';
import 'firebase_list_helper.dart';
import 'playing_card.dart';

/// Represents the current state of the dealing/bidding phase.
///
/// This is synced via Firebase so all players can participate in the
/// bidding and see the deal progress in online mode.
class DealState {
  /// The dealt hands for each player (indexed by player order).
  final List<List<PlayingCard>> hands;

  /// The middle pile (talon/kitty).
  final List<PlayingCard> talon;

  /// Current phase: `'bidding'` or `'callerSetup'`.
  final String phase;

  /// Index of the player whose turn it is to bid.
  final int currentBidderIndex;

  /// The highest bid placed so far, or `null` if no bids yet.
  final Bid? highestBid;

  /// Index of the player who placed the highest bid.
  final int? highestBidderIndex;

  /// Which players have passed (`passed[i] == true` means player i passed).
  final List<bool> passed;

  /// Index of the caller (bid winner) – only meaningful in `callerSetup` phase.
  final int callerIndex;

  /// The chosen trump suit.
  final String trumpName;

  /// The card called to identify the partner (makker), or `null`.
  final PlayingCard? calledCard;

  /// How many talon cards are currently revealed to the caller.
  final int talonRevealCount;

  const DealState({
    required this.hands,
    required this.talon,
    required this.phase,
    required this.currentBidderIndex,
    this.highestBid,
    this.highestBidderIndex,
    required this.passed,
    this.callerIndex = 0,
    this.trumpName = 'spades',
    this.calledCard,
    this.talonRevealCount = 0,
  });

  Suit get trump => Suit.values.byName(trumpName);

  Map<String, dynamic> toJson() => {
        'hands': hands
            .map((h) => h.map((c) => c.toJson()).toList())
            .toList(),
        'talon': talon.map((c) => c.toJson()).toList(),
        'phase': phase,
        'currentBidderIndex': currentBidderIndex,
        'highestBid': highestBid?.toJson(),
        'highestBidderIndex': highestBidderIndex,
        'passed': passed,
        'callerIndex': callerIndex,
        'trumpName': trumpName,
        'calledCard': calledCard?.toJson(),
        'talonRevealCount': talonRevealCount,
      };

  factory DealState.fromJson(Map<String, dynamic> json) => DealState(
        hands: firebaseToList(json['hands'])
            .map((h) => firebaseToList(h)
                .map((c) => PlayingCard.fromJson(
                    Map<String, dynamic>.from(c as Map)))
                .toList())
            .toList(),
        talon: firebaseToList(json['talon'])
            .map((c) =>
                PlayingCard.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        phase: json['phase'] as String,
        currentBidderIndex: json['currentBidderIndex'] as int,
        highestBid: json['highestBid'] != null
            ? Bid.fromJson(
                Map<String, dynamic>.from(json['highestBid'] as Map))
            : null,
        highestBidderIndex: json['highestBidderIndex'] as int?,
        passed: firebaseToList(json['passed']).cast<bool>(),
        callerIndex: json['callerIndex'] as int? ?? 0,
        trumpName: json['trumpName'] as String? ?? 'spades',
        calledCard: json['calledCard'] != null
            ? PlayingCard.fromJson(
                Map<String, dynamic>.from(json['calledCard'] as Map))
            : null,
        talonRevealCount: json['talonRevealCount'] as int? ?? 0,
      );
}
