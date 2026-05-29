%! vim:number
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{guidednotes}[2026/05/21 v1.2 Guided Notes]

% based on the book class
\newif\ifblanks@draft
\blanks@drafttrue                        % default: blank space, no dots
\DeclareOption{draft}{\blanks@drafttrue}
\DeclareOption{final}{\blanks@draftfalse}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\ProcessOptions\relax
\LoadClass[12pt, letterpaper]{book}

\newcommand{\setauthor}[2]{%
  \def\@theauthor{#1}
  \def\@theauthorshort{#2}
}

\newcommand{\setinstitute}[1]{
  \def\@theinstitute{#1}
}

\newcommand{\setcourse}[5]{%
  \def\@thecoursesubject{#1}
  \def\@thecoursesubj{#2}
  \def\@thecoursenumb{#3}
  \def\@thecoursename{#4}
  \def\@thecoursenamesubtitle{#5}
}

\newcommand{\setterm}[2]{%
  \def\@thecourseterm{#1}
  \def\@thecourseyear{#2}
}

\newcommand{\setlogo}[1]{
  \def\@thelogo{#1}
}

\newcommand{\thiscourse}{\@thecoursesubject{}~\@thecoursenumb{}}

% ------------------------------------------------------------
%
%           PACKAGES
%
% ------------------------------------------------------------
% lualatex
\RequirePackage{luacode}

% layout
\RequirePackage{geometry}
\RequirePackage{fancyhdr}
\RequirePackage{ragged2e}
\RequirePackage{multicol}

% latex features
\RequirePackage[inline]{enumitem}
\RequirePackage[framemethod=tikz]{mdframed}
\RequirePackage[dvipsnames]{xcolor}

% math
\RequirePackage{amsmath}
\RequirePackage{amsthm}
\RequirePackage{amssymb}
\RequirePackage{amsfonts}
\RequirePackage{cancel}
\RequirePackage[normalem]{ulem}

% typography
\RequirePackage{microtype}
\RequirePackage{fontawesome5}
\RequirePackage{fontspec}
\RequirePackage{unicode-math}
\RequirePackage{parskip}
\RequirePackage[mathcal]{euscript}
\RequirePackage[sc,center,tiny]{titlesec}
\RequirePackage{csquotes}

% links and pdf
\RequirePackage[hidelinks, pdfusetitle]{hyperref}

% figure and tables
\RequirePackage{float}
\RequirePackage{wrapfig}
\RequirePackage{booktabs}
\RequirePackage{multirow}
\RequirePackage{tikz}
\RequirePackage{pgfplots}
\pgfplotsset{compat=1.18}

% blanks (formerly blanks.sty -- inlined below)
\RequirePackage{keyval}

% subfiles
\RequirePackage{xpatch}
\RequirePackage{standalone}
\RequirePackage{subfiles}

% ------------------------------------------------------------
%
%           BLANKS (inlined from blanks.sty v12.0)
%
%  \ifblanks@draft is declared and the draft/final options are
%  registered in the options section above (before \LoadClass), which
%  is the only place \DeclareOption is legal in a class file.
%
% ------------------------------------------------------------

%% ---- Parameters with defaults -----------------------------------------

\newlength{\blanks@spacing}
\setlength{\blanks@spacing}{0.175in}
\newcommand{\blanks@colour}{gray!40}

%% ---- Draft/final flag -------------------------------------------------
%%
%% \ifblanks@draft is declared and set in the options section above,
%% before \LoadClass, so that \DeclareOption{draft} and
%% \DeclareOption{final} are legal.  Nothing to do here.

%% ---- keyval interface for spacing= and colour= ------------------------

\define@key{blanks}{spacing}{\setlength{\blanks@spacing}{#1}}
\define@key{blanks}{colour} {\renewcommand{\blanks@colour}{#1}}

%% ---- Internal scratch registers ---------------------------------------

\newcount\blanks@cols   % ceiling(width / \blanks@spacing)
\newcount\blanks@rows   % number of rows to draw

\newlength{\blanks@width}   % the active width for the current invocation
\newlength{\blanks@lwid}    % scratch register for ceiling computation

%% \blanks@computecols{<width>}
\newcommand{\blanks@computecols}[1]{%
  \setlength{\blanks@width}{#1}%
  \setlength{\blanks@lwid}{\blanks@width}%
  \addtolength{\blanks@lwid}{\blanks@spacing}%
  \addtolength{\blanks@lwid}{-1sp}%
  \blanks@cols=\blanks@lwid
  \divide\blanks@cols by \blanks@spacing
}

%% ---- Named-box cache (final mode only) --------------------------------

%% \blanks@ensurebox{cols}{rows}
\newcommand{\blanks@ensurebox}[2]{%
  \ifcsname blanksbox#1x#2\endcsname\else
    \expandafter\newbox\csname blanksbox#1x#2\endcsname
    \global\expandafter\setbox\csname blanksbox#1x#2\endcsname
      \hbox{%
        \begin{tikzpicture}[x=\blanks@spacing, y=\blanks@spacing,
                            baseline=0pt, inner sep=0pt, outer sep=0pt]
          \path (0,0) -- (#1, 0);
          \foreach \col in {0, 1, ..., #1}{%
            \foreach \row in {0, 1, ..., \the\numexpr#2-1\relax}{%
              \fill[\blanks@colour] (\col, \row) circle[radius=0.5pt];
            }%
          }%
        \end{tikzpicture}%
      }%
  \fi
}

%% \blanks@ensurerowbox{cols}
\newcommand{\blanks@ensurerowbox}[1]{%
  \ifcsname blanksrow#1\endcsname\else
    \expandafter\newbox\csname blanksrow#1\endcsname
    \global\expandafter\setbox\csname blanksrow#1\endcsname
      \hbox{%
        \begin{tikzpicture}[x=\blanks@spacing, y=\blanks@spacing,
                            baseline=0pt, inner sep=0pt, outer sep=0pt]
          \path (0,0) -- (#1, 0);
          \foreach \col in {0, 1, ..., #1}{%
            \fill[\blanks@colour] (\col, 0) circle[radius=0.5pt];
          }%
        \end{tikzpicture}%
      }%
  \fi
}

%% \blanks@rendergrid{cols}{rows}
\newcommand{\blanks@rendergrid}[2]{%
  \blanks@ensurebox{#1}{#2}%
  \noindent
  \expandafter\copy\csname blanksbox#1x#2\endcsname
  \par
}

%% ---- \blanks[<width>]{n}: fixed number of rows ------------------------

\newcommand{\blanks@fixed}[2][\linewidth]{%
  \ifblanks@draft
    \par\vspace{\dimexpr \blanks@spacing * #2\relax}\par
  \else
    \begingroup
      \parindent\z@
      \hfuzz=\maxdimen
      \par
      \blanks@computecols{#1}%
      \blanks@rendergrid{\the\blanks@cols}{#2}%
      \vspace{\blanks@spacing}%
    \endgroup
  \fi
}

%% ---- \blanks*[<width>]: stretchable fill, snapped to dot-row grid -----

\newcommand{\blanks@fill}[1][\linewidth]{%
  {\parindent\z@\par}%
  \ifblanks@draft
    \vfill
  \else
    \blanks@computecols{#1}%
    \edef\blanks@curcols{\the\blanks@cols}%
    \blanks@ensurerowbox{\blanks@curcols}%
    \leaders\vbox to \blanks@spacing{%
      \vss
      \hbox{\expandafter\copy\csname blanksrow\blanks@curcols\endcsname}%
      \vss
    }\vfill
    \par
  \fi
}

\newcommand{\blanks}{%
  \@ifstar
    {\blanks@fill}%
    {\blanks@fixed}%
}

% ------------------------------------------------------------
%
%           SETUP
%
% ------------------------------------------------------------

% layout
\geometry{margin=0.75in, top=0.25in, bottom=0.25in, nofoot, nomarginpar, includehead, includefoot, headheight=14pt, footskip=7pt, headsep=4pt}

\fancypagestyle{plain}{
  \fancyhf{}
  \fancyhead[OR, EL]{\footnotesize Page~\thepage}
  \renewcommand{\headrulewidth}{0pt}
}
\pagestyle{plain}

\newcommand{\firstpageheader}{}
\fancypagestyle{firstpage}[plain]{
  \ifdefined\@thecourseterm
    \ifdefined\@theauthorshort
      \fancyhead[OL, ER]{\small \@thecoursesubj~\@thecoursenumb~(\@theauthorshort, \@thecourseterm~\@thecourseyear)}
    \else
      \fancyhead[OL, ER]{\small \@thecoursesubj~\@thecoursenumb~(\@thecourseterm~\@thecourseyear)}
    \fi
  \else
    \ifdefined\@theauthorshort
      \fancyhead[OL, ER]{\small \@thecoursesubj~\@thecoursenumb~(\@theauthorshort)}
    \else
      \fancyhead[OL, ER]{\small \@thecoursesubj~\@thecoursenumb}
    \fi
  \fi
  \fancyhead[C]{\small\firstpageheader{}}
  \renewcommand{\headrulewidth}{.4pt}
}


\titlelabel{\thetitle.\;}
% \titleformat{⟨command⟩}[⟨shape⟩]{⟨format⟩}{⟨label⟩}{⟨sep⟩}{⟨before-code⟩}[⟨after-code⟩]
\titleformat{\subsection}{\bfseries}{\thesubsection}{1ex}{}{}
\titleformat{\subsubsection}{}{\thesubsection}{1ex}{}{}

\renewcommand{\UrlFont}{\footnotesize\ttfamily}
\renewcommand{\epsilon}{\varepsilon}
\renewcommand{\emptyset}{\varnothing}
\renewcommand{\arctan}{\tan^{-1}}
\renewcommand{\arcsin}{\sin^{-1}}
\renewcommand{\arccos}{\cos^{-1}}

% framed statements
\surroundwithmdframed[style=withref-compact]{thm}
\surroundwithmdframed[style=withref-compact]{definition}
\surroundwithmdframed[style=withref-compact]{method}

% math
\numberwithin{equation}{chapter}
\theoremstyle{definition}
\newtheorem{stmt}{Statement}[chapter]
\newtheorem{thm}[stmt]{Theorem}
\newtheorem{definition}[stmt]{Definition}
\newtheorem{example}[stmt]{Example}
\newtheorem{discussion}[stmt]{Discussion}
\newtheorem{exercise}[stmt]{Exercise}


% ------------------------------------------------------------
%
%           Fillable notes
%
% ------------------------------------------------------------
\directlua{weeks = {}}

\newcounter{week}
\setcounter{week}{0}
\newenvironment{week}[1]{
  \refstepcounter{week}

  % before code
  % chapter and section numbering
  \setcounter{chapter}{\theweek}
  \setcounter{section}{0}
  \setcounter{stmt}{0}

  % add to toc
  \phantomsection{}\label{week\theweek}
  \addcontentsline{toc}{chapter}{Week~\theweek~(#1)}

  \renewcommand{\firstpageheader}{Week~\theweek~(#1)}
  \thispagestyle{firstpage}

  \def\@weekfirstpage{\the\value{page}}
}{

  \clearpage{\thispagestyle{empty}\cleardoublepage}
  \renewcommand{\firstpageheader}{}
  \directlua{weeks[\theweek] = \the\value{page}}
}

\newcommand{\textbook}[1]{\noindent{} {\footnotesize \faBookReader{} #1 \hfill}}

\newdimen\vremaining
\directlua{
  function calc_remaining_lines()
    local h = tex.dimen.vremaining / 65535 / 72.27
    local n = math.floor(h / 0.175) - 1
    tex.print(n)
  end
}

\newcommand{\blanklines}[2][\medskipamount]{
  \blanks{#2}
}

\mdfdefinestyle{wide}{
  innertopmargin=1em,
  innerleftmargin=1em,
  innerbottommargin=1em,
  innerrightmargin=1em,
  skipabove=1em,
  skipbelow=1em,
  align=center,
  roundcorner=3pt,
}
\mdfdefinestyle{simple}{
  userdefinedwidth=0.9\textwidth,
  innertopmargin=1em,
  innerleftmargin=1em,
  innerbottommargin=1em,
  innerrightmargin=1em,
  skipabove=1em,
  skipbelow=1em,
  align=center,
  roundcorner=3pt,
  startinnercode={\linespread{1.5}\selectfont}
}

\mdfdefinestyle{simple-compact}{
  userdefinedwidth=0.9\textwidth,
  innertopmargin=1em,
  innerleftmargin=1em,
  innerbottommargin=1em,
  innerrightmargin=1em,
  skipabove=1em,
  skipbelow=1em,
  align=center,
  roundcorner=3pt,
}

\mdfdefinestyle{sidenote}{
  userdefinedwidth=0.3\textwidth,
  innertopmargin=1em,
  innerleftmargin=1em,
  innerbottommargin=1em,
  innerrightmargin=1em,
  skipabove=1em,
  skipbelow=1em,
  align=right,
  topline=false,
  rightline=false,
  bottomline=false,
  startinnercode={\footnotesize}
}

\mdfdefinestyle{withref}{
  userdefinedwidth=0.9\textwidth,
  innertopmargin=1em,
  innerleftmargin=1em,
  innerbottommargin=0.25em,
  innerrightmargin=1em,
  skipabove=1em,
  skipbelow=1em,
  align=center,
  roundcorner=3pt,
  startinnercode={\linespread{1.5}\selectfont}
}

\mdfdefinestyle{withref-compact}{
  userdefinedwidth=0.9\textwidth,
  innertopmargin=1em,
  innerleftmargin=1em,
  innerbottommargin=0.25em,
  innerrightmargin=1em,
  skipabove=1em,
  skipbelow=1em,
  align=center,
  roundcorner=3pt,
}

% ------------------------------------------------------------
%
%           front matter
%
% ------------------------------------------------------------
\ifSubfilesClassLoaded{}{\AtBeginDocument{
      \begin{titlepage}
        \thispagestyle{empty}

        % show a logo if defined.
        % \ifdefined requires lualatex.
        \ifdefined\@thelogo
          \begin{tikzpicture}[remember picture, overlay]
            \node[anchor=north east, inner sep=1cm]
              at (current page.north east)
              {\includegraphics[width=3in]{\@thelogo}};
          \end{tikzpicture}
        \fi

        % Push title block into the upper third
        \vspace*{0.20\textheight}

        \hspace*{1in}\parbox{6in}{\Huge\bfseries\@thecoursesubj~\@thecoursenumb:~\@thecoursename}

        \ifdefined\@thecoursenamesubtitle
          \hspace*{1in}{\Huge\@thecoursenamesubtitle}
        \fi

        \hspace*{1in}{\color{gray}\hrulefill{}}

        \ifdefined\@thecourseterm
          \hspace*{1in}{\large\@thecourseterm~\@thecourseyear}
        \fi

        \vspace{1in}

        \hspace*{1in}{\Large\@theauthor} \medskip

        \ifdefined\@theinstitute
          \hspace*{1in}{\Large\@theinstitute}
        \fi

        \bigskip

        % create a blank page
        \clearpage{\thispagestyle{empty}\cleardoublepage}
      \end{titlepage}
  \directlua{titlepage = \the\value{page} - 1}

  \frontmatter{}
  \pagenumbering{roman}

  \renewcommand{\contentsname}{Table of Contents}
  \phantomsection{} \label{toc}
  \addcontentsline{toc}{chapter}{\contentsname}
  \tableofcontents{}
  \clearpage

  \clearpage{\thispagestyle{empty}\cleardoublepage}
  \directlua{frontmatter = \the\value{page} - 1}  % has to be the last line of the front matter

  \mainmatter{}
}}
