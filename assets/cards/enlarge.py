import re
import sys
from pathlib import Path


# ============================================================
# CONFIGURATION
# ============================================================

# The ONLY value you need to change.
#
# The original deck's corner rank is 78.
# SIZE = 130 gives the enlarged version we have been using.
SIZE = 150


# ============================================================
# DERIVED SIZES
# ============================================================

# Original proportions:
#
# Corner rank  = 78
# Corner suit  = 65
# Center suit  = 104

CORNER_RANK_SIZE = SIZE
CORNER_SUIT_SIZE = round(SIZE * 65 / 78)
CENTER_SUIT_SIZE = round(SIZE * 104 / 78)


# ============================================================
# LAYOUT
# ============================================================

# Horizontal safety adjustment for multi-character ranks.
#
# At SIZE=130, "10" is wider than A/K/Q/J/etc.
#
# 16 SVG units is approximately 1rem at the scale of these
# cards.
MULTI_CHARACTER_X_OFFSET = round(SIZE * 16 / 130)


# Corner rank/suit spacing.
#
# These are expressed relative to SIZE rather than being fixed
# pixel values.
RANK_TO_SUIT_GAP = round(SIZE * 0.10)

# Small amount of safety space around the card edges.
EDGE_MARGIN = round(SIZE * 0.12)


# ============================================================
# SVG HELPERS
# ============================================================

SUIT_CHARS = "♣♠♥♦"


def get_viewbox(svg):
    """Return SVG viewBox as (x, y, width, height)."""

    match = re.search(
        r'viewBox\s*=\s*["\']\s*'
        r'([-+]?\d*\.?\d+)\s+'
        r'([-+]?\d*\.?\d+)\s+'
        r'([-+]?\d*\.?\d+)\s+'
        r'([-+]?\d*\.?\d+)\s*'
        r'["\']',
        svg,
        flags=re.IGNORECASE,
    )

    if not match:
        raise ValueError("SVG does not contain a valid viewBox.")

    return tuple(map(float, match.groups()))


def get_attr(element, name):
    """Get an XML/SVG attribute."""

    match = re.search(
        rf'\b{re.escape(name)}\s*=\s*["\']([^"\']*)["\']',
        element,
        flags=re.IGNORECASE,
    )

    return match.group(1) if match else None


def set_attr(element, name, value):
    """Set an existing SVG attribute or add it if missing."""

    pattern = (
        rf'(\b{re.escape(name)}\s*=\s*)'
        rf'(["\'])[^"\']*\2'
    )

    if re.search(pattern, element, flags=re.IGNORECASE):

        return re.sub(
            pattern,
            rf'\g<1>"{value}"',
            element,
            count=1,
            flags=re.IGNORECASE,
        )

    return re.sub(
        r'<text\b',
        f'<text {name}="{value}"',
        element,
        count=1,
        flags=re.IGNORECASE,
    )


def get_text(element):
    """Extract visible text from an SVG text element."""

    match = re.search(
        r'>(.*?)</text>',
        element,
        flags=re.DOTALL | re.IGNORECASE,
    )

    if not match:
        return ""

    text = re.sub(
        r'<[^>]+>',
        '',
        match.group(1),
    )

    return text.strip()


def replace_text_element(
    group,
    predicate,
    callback,
):
    """
    Replace the first <text> element in a group matching
    predicate(text_element).
    """

    pattern = r'<text\b[^>]*>.*?</text>'

    def replacer(match):

        element = match.group(0)

        if predicate(element):
            return callback(element)

        return element

    return re.sub(
        pattern,
        replacer,
        group,
        count=0,
        flags=re.DOTALL | re.IGNORECASE,
    )


# ============================================================
# CORNER GROUP DETECTION
# ============================================================

def find_corner_groups(svg):
    """
    Find the two card-corner <g> elements.

    We specifically look for groups containing:
        - font-weight="900" rank text
        - a suit symbol

    This avoids touching the center suit symbols.
    """

    groups = []

    # This matches the complete <g>...</g> used by the corner
    # structures in the supplied SVG.
    pattern = r'<g\b[^>]*transform\s*=\s*["\'][^"\']*translate\([^)]*\)[^"\']*["\'][^>]*>.*?</g>'

    for match in re.finditer(
        pattern,
        svg,
        flags=re.DOTALL | re.IGNORECASE,
    ):

        group = match.group(0)

        has_rank = re.search(
            r'<text\b[^>]*font-weight\s*=\s*["\']900["\'][^>]*>.*?</text>',
            group,
            flags=re.DOTALL | re.IGNORECASE,
        )

        has_suit = re.search(
            rf'<text\b[^>]*>\s*[{SUIT_CHARS}]\s*</text>',
            group,
            flags=re.DOTALL | re.IGNORECASE,
        )

        if has_rank and has_suit:
            groups.append(
                (
                    match.start(),
                    match.end(),
                    group,
                )
            )

    return groups


# ============================================================
# CORNER LAYOUT
# ============================================================

def calculate_corner_group_position(
    rank,
    is_bottom,
    viewbox,
):
    """
    Calculate a safe corner-group translation.

    The supplied SVG already has sensible corner anchor points:

        top-left     (91, 118)
        bottom-right (659, 932)

    We preserve those proportions but compensate for the
    enlarged rank.

    Multi-character ranks receive a small horizontal correction.
    """

    _, _, width, height = viewbox

    # --------------------------------------------------------
    # Original proportional anchor points
    # --------------------------------------------------------

    if not is_bottom:

        x = width * 91 / 750
        y = height * 118 / 1050

    else:

        x = width * 659 / 750
        y = height * 932 / 1050

    # --------------------------------------------------------
    # Multi-character rank adjustment
    # --------------------------------------------------------

    if len(rank) > 1:

        if not is_bottom:
            # Move top-left rank slightly right.
            x += MULTI_CHARACTER_X_OFFSET

        else:
            # The bottom group is rotated 180 degrees.
            #
            # Therefore local negative X moves the visible rank
            # to the right.
            x += MULTI_CHARACTER_X_OFFSET

    return round(x), round(y)


# ============================================================
# PROCESS ONE CORNER GROUP
# ============================================================

def process_corner_group(
    group,
    is_bottom,
    viewbox,
):
    """
    Resize and reposition one corner group.

    The group structure is:

        <g transform="translate(...)">
            <text ... rank>...</text>
            <text ... suit>...</text>
        </g>

    We keep the group's rotation intact.
    """

    # --------------------------------------------------------
    # Find rank
    # --------------------------------------------------------

    rank_match = re.search(
        r'<text\b[^>]*font-weight\s*=\s*["\']900["\'][^>]*>.*?</text>',
        group,
        flags=re.DOTALL | re.IGNORECASE,
    )

    if not rank_match:
        return group, None

    rank_element = rank_match.group(0)

    rank = get_text(rank_element)

    if not rank:
        return group, None

    # --------------------------------------------------------
    # Find suit
    # --------------------------------------------------------

    suit_match = re.search(
        rf'<text\b[^>]*>\s*[{SUIT_CHARS}]\s*</text>',
        group,
        flags=re.DOTALL | re.IGNORECASE,
    )

    if not suit_match:
        return group, rank

    suit_element = suit_match.group(0)

    # ========================================================
    # RANK
    # ========================================================

    new_rank = set_attr(
        rank_element,
        "font-size",
        CORNER_RANK_SIZE,
    )

    # The original SVG uses:
    #
    #     y="0"
    #
    # Keep the rank baseline at the group's anchor because
    # the group itself determines its card position.
    new_rank = set_attr(
        new_rank,
        "y",
        0,
    )

    # --------------------------------------------------------
    # Horizontal correction for "10"
    # --------------------------------------------------------

    if len(rank) > 1:

        if not is_bottom:

            # Top-left:
            #
            # positive X = visually right
            #
            new_rank = set_attr(
                new_rank,
                "x",
                MULTI_CHARACTER_X_OFFSET,
            )

        else:

            # Bottom-right is rotated 180 degrees.
            #
            # Therefore negative local X = visually right.
            #
            new_rank = set_attr(
                new_rank,
                "x",
                -MULTI_CHARACTER_X_OFFSET,
            )

    else:

        # Single-character ranks stay centered.
        new_rank = set_attr(
            new_rank,
            "x",
            0,
        )

    # ========================================================
    # SUIT
    # ========================================================

    new_suit = set_attr(
        suit_element,
        "font-size",
        CORNER_SUIT_SIZE,
    )

    # --------------------------------------------------------
    # Dynamically position suit below rank.
    #
    # Original:
    #
    # rank y  = 0
    # suit y  = 72
    #
    # We scale the original relationship while adding enough
    # room for the larger rank.
    # --------------------------------------------------------

    suit_y = (
        CORNER_RANK_SIZE * 0.82
        + RANK_TO_SUIT_GAP
    )

    new_suit = set_attr(
        new_suit,
        "y",
        round(suit_y),
    )

    # ========================================================
    # Replace rank and suit in the group
    # ========================================================

    group = (
        group[:rank_match.start()]
        + new_rank
        + group[rank_match.end():]
    )

    # Find suit again because rank replacement changed indexes.
    suit_match = re.search(
        rf'<text\b[^>]*>\s*[{SUIT_CHARS}]\s*</text>',
        group,
        flags=re.DOTALL | re.IGNORECASE,
    )

    if suit_match:

        group = (
            group[:suit_match.start()]
            + new_suit
            + group[suit_match.end():]
        )

    # ========================================================
    # Update group translation
    # ========================================================

    new_x, new_y = calculate_corner_group_position(
        rank,
        is_bottom,
        viewbox,
    )

    # Replace only the translate() coordinates.
    group = re.sub(
        r'translate\(\s*[-+]?\d*\.?\d+\s*,\s*[-+]?\d*\.?\d+\s*\)',
        f"translate({new_x},{new_y})",
        group,
        count=1,
    )

    return group, rank


# ============================================================
# SVG PROCESSING
# ============================================================

def enlarge_card_svg(svg_file):

    svg_file = Path(svg_file)

    svg = svg_file.read_text(
        encoding="utf-8"
    )

    viewbox = get_viewbox(svg)

    # --------------------------------------------------------
    # Find corner groups
    # --------------------------------------------------------

    corners = find_corner_groups(svg)

    if len(corners) < 2:

        raise ValueError(
            f"Expected 2 corner groups, found {len(corners)}"
        )

    # --------------------------------------------------------
    # Process from bottom to top so string positions remain
    # valid.
    # --------------------------------------------------------

    processed = []

    for index, (start, end, group) in enumerate(
        reversed(corners)
    ):

        # Because we reversed the list:
        #
        # index 0 = original last group
        #
        # Determine whether this is bottom-right by looking
        # for rotate(180).
        is_bottom = bool(
            re.search(
                r'rotate\s*\(\s*180',
                group,
                flags=re.IGNORECASE,
            )
        )

        new_group, rank = process_corner_group(
            group,
            is_bottom,
            viewbox,
        )

        processed.append(
            (start, end, new_group, rank, is_bottom)
        )

    # --------------------------------------------------------
    # Replace groups backwards in the SVG.
    # --------------------------------------------------------

    for start, end, new_group, _, _ in processed:

        svg = (
            svg[:start]
            + new_group
            + svg[end:]
        )

    # ========================================================
    # CENTER SUITS
    # ========================================================

    # IMPORTANT:
    #
    # We intentionally process ONLY suit text elements that
    # are NOT inside the two corner groups.
    #
    # This prevents the bottom corner from accidentally being
    # interpreted as a center suit.

    corner_ranges = []

    # Re-scan the updated SVG.
    for match in re.finditer(
        r'<g\b[^>]*transform\s*=\s*["\'][^"\']*translate\([^)]*\)[^"\']*["\'][^>]*>.*?</g>',
        svg,
        flags=re.DOTALL | re.IGNORECASE,
    ):

        group = match.group(0)

        if (
            re.search(
                r'font-weight\s*=\s*["\']900["\']',
                group,
                flags=re.IGNORECASE,
            )
            and
            re.search(
                rf'>\s*[{SUIT_CHARS}]\s*</text>',
                group,
                flags=re.DOTALL,
            )
        ):
            corner_ranges.append(
                (match.start(), match.end())
            )

    # --------------------------------------------------------
    # Modify suit elements outside corner groups.
    # --------------------------------------------------------

    replacements = []

    for match in re.finditer(
        rf'<text\b[^>]*>\s*[{SUIT_CHARS}]\s*</text>',
        svg,
        flags=re.DOTALL | re.IGNORECASE,
    ):

        position = match.start()

        inside_corner = any(
            start <= position < end
            for start, end in corner_ranges
        )

        if inside_corner:
            continue

        element = match.group(0)

        # Only enlarge existing center-sized suits.
        font_size = get_attr(
            element,
            "font-size",
        )

        if font_size is None:
            continue

        try:
            numeric_size = float(
                re.match(
                    r'[-+]?\d*\.?\d+',
                    font_size,
                ).group(0)
            )
        except (AttributeError, ValueError):
            continue

        # The original center suit is 104.
        #
        # This avoids accidentally changing the small decorative
        # suit near the title.
        if abs(numeric_size - 104) > 0.1:
            continue

        new_element = set_attr(
            element,
            "font-size",
            CENTER_SUIT_SIZE,
        )

        replacements.append(
            (
                match.start(),
                match.end(),
                new_element,
            )
        )

    # Apply center replacements backwards.
    for start, end, replacement in reversed(
        replacements
    ):

        svg = (
            svg[:start]
            + replacement
            + svg[end:]
        )

    # ========================================================
    # WRITE FILE
    # ========================================================

    svg_file.write_text(
        svg,
        encoding="utf-8",
    )

    # --------------------------------------------------------
    # Print useful information
    # --------------------------------------------------------

    ranks = []

    for match in re.finditer(
        r'<g\b[^>]*transform\s*=\s*["\'][^"\']*translate\([^)]*\)[^"\']*["\'][^>]*>.*?</g>',
        svg,
        flags=re.DOTALL | re.IGNORECASE,
    ):

        rank_match = re.search(
            r'<text\b[^>]*font-weight\s*=\s*["\']900["\'][^>]*>.*?</text>',
            match.group(0),
            flags=re.DOTALL | re.IGNORECASE,
        )

        if rank_match:
            ranks.append(
                get_text(rank_match.group(0))
            )

    print(
        f"Updated: {svg_file.name:<30} "
        f"ranks={ranks}"
    )


# ============================================================
# DIRECTORY PROCESSING
# ============================================================

def process_directory(directory):

    directory = Path(directory)

    if not directory.is_dir():

        print(
            f"Error: Directory does not exist: {directory}"
        )

        sys.exit(1)

    # Only SVGs directly inside this directory.
    svg_files = sorted(
        directory.glob("*.svg")
    )

    if not svg_files:

        print(
            f"No SVG files found in: {directory}"
        )

        return

    print("=" * 70)
    print("1920s CARD SVG TRANSFORMER")
    print("=" * 70)
    print(f"Directory : {directory}")
    print(f"SVG files : {len(svg_files)}")
    print(f"SIZE      : {SIZE}")
    print(
        f"Rank      : {CORNER_RANK_SIZE}"
    )
    print(
        f"Corner    : {CORNER_SUIT_SIZE}"
    )
    print(
        f"Center    : {CENTER_SUIT_SIZE}"
    )
    print("=" * 70)
    print()

    successful = 0
    failed = 0

    for svg_file in svg_files:

        try:

            enlarge_card_svg(svg_file)
            successful += 1

        except Exception as error:

            failed += 1

            print(
                f"ERROR: {svg_file.name}: {error}"
            )

    print()
    print("=" * 70)
    print("DONE")
    print("=" * 70)
    print(f"Updated : {successful}")
    print(f"Failed  : {failed}")
    print("=" * 70)


# ============================================================
# COMMAND LINE
# ============================================================

if __name__ == "__main__":

    if len(sys.argv) != 2:

        print("Usage:")
        print()
        print(
            "  python enlarge_svg.py <directory>"
        )
        print()
        print("Example:")
        print()
        print(
            "  python enlarge_svg.py ./cards"
        )
        print()

        sys.exit(1)

    process_directory(
        sys.argv[1]
    )
