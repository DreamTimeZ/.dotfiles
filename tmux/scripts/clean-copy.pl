#!/usr/bin/env perl
use strict;
use warnings;
use Pod::Usage;
use Pod::Text;

# Handle help flags and TTY detection
if (@ARGV && $ARGV[0] =~ /^-h$/) {
    pod2usage(-verbose => 1, -exitval => 0);
}
if (@ARGV && $ARGV[0] =~ /^--help$/) {
    # Use Pod::Text to format full docs (doesn't require perl-doc)
    Pod::Text->new(sentence => 0, width => 78)->parse_from_file($0);
    exit 0;
}
if (-t STDIN && !@ARGV) {
    pod2usage(-verbose => 1, -exitval => 0, -message => "No input provided.\n");
}

# Slurp entire input for multi-line processing
local $/ = undef;
my $text = <STDIN>;

# === PHASE 1: NORMALIZE INPUT ===
$text =~ s/\r\n/\n/g;           # Windows → Unix line endings
$text =~ s/^  //gm;             # Strip 2 leading spaces (Claude Code padding)
$text =~ s/[ \t]*$//gm;         # Strip trailing whitespace

# === PHASE 2: PROTECT CONTENT ===
$text =~ s/^([-*=]{3,})$/$1\x00/gm;   # Horizontal rules → marker \x00
$text =~ s/^(#+ .*)$/$1\x01/gm;       # Markdown headers → marker \x01

# === PHASE 3: CONVERT TABLES ===
$text =~ s/^[ \t]*┌[─┬]+┐\n?//gm;     # Remove top borders
$text =~ s/^[ \t]*└[─┴]+┘\n?//gm;     # Remove bottom borders

# Convert first separator to markdown, remove subsequent ones
my $first_sep = 1;
$text =~ s/^([ \t]*)├([─┼]+)┤\n?/
    if ($first_sep) {
        $first_sep = 0;
        $1 . "|" . join("|", map { "---" } split(\/┼\/, $2)) . "|\n";
    } else {
        "";
    }
/gme;

$text =~ s/│/|/g;  # Box-drawing vertical bars → markdown pipes

# === PHASE 4: JOIN SOFT-WRAPPED LINES ===
# Replace \n with space UNLESS lookbehind/lookahead matches preservation rules
$text =~ s/(?<![.!?:\n|])(?<!\x00)(?<!\x01)\n(?!\n)(?![-*+|>])(?!#+ )(?!\d+[.)])(?![a-zA-Z][.)])(?![ivxlcdm]{2,}[.)])(?![IVXLCDM]{2,}[.)])(?![ \t])/ /g;

# === PHASE 5: CLEANUP ===
$text =~ s/\x00//g;             # Remove horizontal rule markers
$text =~ s/\x01//g;             # Remove header markers
$text =~ s/(\w)- (\w)/$1-$2/g;  # Fix soft-wrapped hyphens

print $text;

__END__

=head1 NAME

clean-copy.pl - Intelligent copy filter for Claude Code terminal output

=head1 SYNOPSIS

    <selection> | clean-copy.pl | <clipboard>

    clean-copy.pl -h          # Brief help
    clean-copy.pl --help      # Full documentation

Used by tmux B<Shift+y> binding in copy mode.

=head1 DESCRIPTION

Claude Code adds 2 leading spaces to all output and soft-wraps text at the
terminal width. This script intelligently cleans up that formatting while
preserving intentional structure like lists, code blocks, and paragraphs.

=head2 What It Does

=over 4

=item * Strips 2 leading spaces (Claude Code UI padding)

=item * Joins soft-wrapped lines into continuous paragraphs

=item * Fixes hyphenated words broken across lines (C<high-\nperf> → C<high-perf>)

=item * Converts box-drawing tables to markdown format

=item * Collapses multiple table separator rows to one

=back

=head2 What It Preserves

=over 4

=item * Sentence endings (. ? ! :) keep their newlines

=item * Blank lines (paragraph separators)

=item * All list types (see L</SUPPORTED LISTS>)

=item * Indentation (code blocks, nested content)

=item * Horizontal rules (--- *** ===)

=item * Markdown headers (# ## ###)

=item * Blockquotes (> lines)

=back

=head1 SUPPORTED LISTS

    Bullets:     - item    * item    + item
    Numbered:    1. item   10. item  1) item   10) item
    Letters:     a. item   A. item   a) item   A) item
    Roman:       i. item   iv. item  I. item   IV. item
                 (full range: i-mmmcmxcix, I-MMMCMXCIX)

=head1 TABLE CONVERSION

Claude Code renders tables with box-drawing characters:

    ┌──────┬──────┐
    │ A    │ B    │
    ├──────┼──────┤
    │ 1    │ 2    │
    └──────┴──────┘

This script converts them to markdown:

    | A    | B    |
    |---|---|
    | 1    | 2    |

Multiple separator rows (Claude Code adds one after each row) are collapsed
to a single separator after the header.

=head1 ALGORITHM

The script processes text in five phases:

=over 4

=item 1. B<Normalize> - Convert line endings, strip Claude Code padding

=item 2. B<Protect> - Mark horizontal rules and headers with special bytes

=item 3. B<Tables> - Convert box-drawing to markdown format

=item 4. B<Join> - Replace newlines with spaces using lookbehind/lookahead rules

=item 5. B<Cleanup> - Remove markers, fix hyphenated words

=back

=head2 Join Logic

The core regex replaces C<\n> with space unless:

B<Lookbehind> (don't join if line ends with):

    .!?:    Sentence-ending punctuation
    \n      Already a blank line
    |       Table row
    \x00    Protected horizontal rule
    \x01    Protected markdown header

B<Lookahead> (don't join if next line starts with):

    \n          Blank line
    - * + | >   List markers, blockquotes
    #           Markdown headers
    \d+[.)]     Numbered lists
    [a-zA-Z][.)]    Letter lists
    [ivxlcdm]{2,}[.)]   Roman numerals (lowercase)
    [IVXLCDM]{2,}[.)]   Roman numerals (uppercase)
    [ \t]       Indented content

=head1 TMUX INTEGRATION

Bound to B<Shift+y> in copy mode:

    bind -T copy-mode-vi Y send -X copy-pipe-and-cancel \
        "$ZDOTFILES_DIR/tmux/scripts/clean-copy.pl | <clipboard>"

Platform-specific clipboard commands:

    macOS:   pbcopy
    WSL:     /mnt/c/Windows/System32/clip.exe
    X11:     xclip -selection clipboard
    Wayland: wl-copy

Requires C<$ZDOTFILES_DIR> environment variable to be set (typically in shell config).

=head1 WHEN TO USE

=over 4

=item B<y> (raw copy)

Code, logs, configs — exact whitespace matters.

=item B<Shift+y> (clean copy)

Prose, documentation, explanations from Claude Code.

=back

=head1 LIMITATIONS

=over 4

=item * Text after list items without punctuation may join with next line

=item * Single-letter lines may join (A\nB\nC → A B C)

=item * Multiple tables: each gets its own separator row

=back

=head1 FILES

    $ZDOTFILES_DIR/tmux/scripts/clean-copy.pl   This script
    $ZDOTFILES_DIR/tmux/.tmux.conf              Keybinding configuration
    $ZDOTFILES_DIR/tmux/CHEATSHEET.md           Quick reference

Where C<$ZDOTFILES_DIR> defaults to C<~/.dotfiles>.

=head1 AUTHOR

Generated with Claude Code assistance.

=cut
