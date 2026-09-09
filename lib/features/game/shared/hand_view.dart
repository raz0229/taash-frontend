import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import 'hand_order.dart';
import 'playing_card.dart';

class HandView extends StatefulWidget {
  const HandView({
    super.key,
    required this.hand,
    required this.onChanged,
    required this.multiSelect,
    required this.canSelect,
    required this.canPlay,
    required this.isYourTurn,
    this.onDrop,
    this.sortByRank,
    this.allowSort = false,
  });
  final HandOrder hand;
  final VoidCallback onChanged;
  final bool multiSelect, canSelect, allowSort, isYourTurn;
  final bool? sortByRank;
  final bool Function(String) canPlay;
  final void Function(String)? onDrop;

  @override
  State<HandView> createState() => _HandViewState();
}

class _HandViewState extends State<HandView> {
  bool collapsed = false;

  @override
  void didUpdateWidget(HandView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isYourTurn && !oldWidget.isYourTurn && collapsed) {
      setState(() => collapsed = false);
    }
  }

  void _select(BuildContext context, String card) {
    if (!widget.canSelect) return;
    if (!widget.hand.toggle(card, limit: widget.multiSelect ? 4 : 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Copy.chooseUpToFourCardsForBluff)),
      );
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.hand.cards;
    final compact =
        MediaQuery.sizeOf(context).height < 720 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.4;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 10 && !collapsed) {
          setState(() => collapsed = true);
        } else if (details.primaryDelta! < -10 && collapsed) {
          setState(() => collapsed = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        decoration: const BoxDecoration(
          color: Color(0xff19122E),
          border: Border(top: BorderSide(color: Color(0xff705091))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    Copy.yourHAND(cards.length),
                    style: const TextStyle(
                      color: Color(0xffCBBFE3),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (widget.hand.selected.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      widget.hand.clearSelection();
                      widget.onChanged();
                    },
                    child: const Text(
                      Copy.clear,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (widget.allowSort)
                  IconButton(
                    tooltip: widget.sortByRank == true
                        ? Copy.sortByRank
                        : Copy.sortBySuitAndRank,
                    onPressed: () {
                      widget.hand.sort(byRank: widget.sortByRank ?? false);
                      widget.onChanged();
                    },
                    icon: const Icon(Icons.sort_rounded, color: Colors.white),
                  ),
                IconButton(
                  tooltip: Copy.inspectAndArrangeYourCards,
                  onPressed: () => _arrange(context),
                  icon: const Icon(
                    Icons.view_agenda_outlined,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: collapsed ? 'Expand hand' : 'Collapse hand',
                  onPressed: () => setState(() => collapsed = !collapsed),
                  icon: Icon(
                    collapsed ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: collapsed
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cards.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Text(
                              Copy.yourHandIsEmptyFollowTheRoom,
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        else
                          SizedBox(
                            height: compact ? 90 : 124,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              child: SizedBox(
                                width: (cards.length - 1) * 42 + 104,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    for (var i = 0; i < cards.length; i++)
                                      _card(context, cards[i], i),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            widget.hand.selected.isEmpty
                                ? Copy.tapToSelectHoldToDragArrange
                                : '${widget.hand.selected.length} selected · tap the action below or drag to the room',
                            style: const TextStyle(fontSize: 11, color: Color(0xffCBBFE3)),
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

  Widget _card(BuildContext context, String card, int index) {
    final selected = widget.hand.selected.contains(card);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedPositioned(
      key: ValueKey(card),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
      left: index * 42 + 12,
      top: selected ? 0 : 4 + (index - (widget.hand.cards.length - 1) / 2).abs() * 2,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => details.data != card,
        onAcceptWithDetails: (details) {
          widget.hand.move(details.data, index);
          widget.onChanged();
        },
        builder: (context, candidate, rejected) => LongPressDraggable<String>(
          data: card,
          maxSimultaneousDrags: widget.canSelect ? 1 : 0,
          feedback: Material(
            type: MaterialType.transparency,
            child: PlayingCard(card: card, width: 76, selected: true),
          ),
          childWhenDragging: Opacity(
            opacity: .3,
            child: PlayingCard(card: card, selected: selected),
          ),
          child: Transform.rotate(
            angle: ((index - (widget.hand.cards.length - 1) / 2) * .045).clamp(
              -.22,
              .22,
            ),
            alignment: Alignment.bottomCenter,
            child: PlayingCard(
              card: card,
              width:
                  MediaQuery.sizeOf(context).height < 720 &&
                      MediaQuery.textScalerOf(context).scale(1) <= 1.4
                  ? 52
                  : 72,
              selected: selected || candidate.isNotEmpty,
              available: !widget.canSelect || widget.canPlay(card),
              onTap: widget.canSelect ? () => _select(context, card) : null,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _arrange(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          void changed() {
            widget.onChanged();
            setSheetState(() {});
          }

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .8,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      Copy.yourCardsYourOrder,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(Copy.useTheArrowsToArrangeYourHand),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.hand.cards.length,
                      itemBuilder: (context, index) {
                        final card = widget.hand.cards[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              PlayingCard(card: card, width: 42),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  CardIdentity.parse(card).label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: Copy.moveEarlier(
                                  CardIdentity.parse(card).label,
                                ),
                                onPressed: index == 0
                                    ? null
                                    : () {
                                        widget.hand.move(card, index - 1);
                                        changed();
                                      },
                                icon: const Icon(Icons.arrow_upward_rounded),
                              ),
                              IconButton(
                                tooltip: Copy.moveLater(
                                  CardIdentity.parse(card).label,
                                ),
                                onPressed: index == widget.hand.cards.length - 1
                                    ? null
                                    : () {
                                        widget.hand.move(card, index + 1);
                                        changed();
                                      },
                                icon: const Icon(Icons.arrow_downward_rounded),
                              ),
                              if (widget.canSelect)
                                IconButton(
                                  tooltip: widget.hand.selected.contains(card)
                                      ? Copy.deselectCard
                                      : Copy.selectCard,
                                  onPressed: () {
                                    _select(context, card);
                                    setSheetState(() {});
                                  },
                                  icon: Icon(
                                    widget.hand.selected.contains(card)
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text(Copy.backToTheRoom2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
