\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{guidednotes}[2025/04/08 v1.0 Guided Notes]

% based on the book class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\ProcessOptions
\LoadClass[12pt, letterpaper]{book}

\newcommand{\setauthor}[2]{%
  \def\@theauthor{#1}
  \def\@theinstitute{#2}
}

\newcommand{\setcourse}[4]{%
  \def\@thecoursesubject{#1}
  \def\@thecoursesubj{#2}
  \def\@thecoursenumb{#3}
  \def\@thecoursename{#4}
}

\newcommand{\setterm}[3]{%
  \def\@thecourseterm{Fall}
  \def\@thecourseyear{2025}
  \def\@thecoursebreak{2025}
}

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

% typography
\RequirePackage{microtype} 
\RequirePackage{fontawesome5}
\RequirePackage{fontspec}
\RequirePackage{unicode-math}
\RequirePackage{parskip}
\RequirePackage[mathcal]{euscript}
\RequirePackage[sc,center,tiny]{titlesec}

% links and pdf
\RequirePackage[hidelinks, pdfusetitle]{hyperref}

% figure and tables
\RequirePackage{float}
\RequirePackage{booktabs}
\RequirePackage{tikz}
\RequirePackage{pgfplots}

% subfiles
\RequirePackage{refcount, xr, subfiles}
% ------------------------------------------------------------
%
%           SETUP
%
% ------------------------------------------------------------

% layout
\geometry{margin=0.75in, top=0.25in, bottom=0.25in, nofoot, nomarginpar, includehead, includefoot, headheight=15pt, footskip=15pt}

% page styles
\pagestyle{fancy}
\fancyhf{}
\fancyhead[OR, EL]{\small Page~\thepage}
\renewcommand{\headrulewidth}{0pt}

\newcommand{\firstpageheader}{}
\fancypagestyle{firstpage}[fancy]{
  \fancyhead[OL, ER]{\small \@thecoursesubj~\@thecoursenumb~(\@thecourseterm~\@thecourseyear)}
  \fancyhead[C]{\small\firstpageheader{}}
  \renewcommand{\headrulewidth}{.4pt}
}


\titlelabel{\thetitle.\;}
% \titleformat{⟨command⟩}[⟨shape⟩]{⟨format⟩}{⟨label⟩}{⟨sep⟩}{⟨before-code⟩}[⟨after-code⟩]
\titleformat{\subsection}{\bfseries}{\thesubsection}{1ex}{}{}
\titleformat{\subsubsection}{}{\thesubsection}{1ex}{}{}

% typography
\everymath{\displaystyle}
\setmainfont{STIX Two Text}
\setmathfont{STIX Two Math}

\renewcommand{\UrlFont}{\footnotesize\ttfamily}
\renewcommand{\epsilon}{\varepsilon}
\renewcommand{\emptyset}{\varnothing}
\renewcommand{\arctan}{\tan^{-1}}
\renewcommand{\arcsin}{\sin^{-1}}
\renewcommand{\arccos}{\cos^{-1}}

% math
\numberwithin{equation}{chapter}
\theoremstyle{definition}
\newtheorem{thm}{Theorem}
\newtheorem{example}[thm]{Example}

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

  % befor code
  % chapter and section numbering
  \setcounter{chapter}{\theweek}
  \setcounter{section}{0}
  \setcounter{thm}{0}

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
\newcommand{\blanklines}[1]{
  \par
  \includegraphics{./standalones/build/grid_#1_by_40.pdf}
  \smallbreak
}

\mdfdefinestyle{wide}{
  % userdefinedwidth=0.95\textwidth,
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
\AtBeginDocument{
  \begin{titlepage}
    \thispagestyle{empty}
    \huge

    \begin{center}
      % title
      \phantom{top}
      \vspace{1in}

      {\Huge\bfseries \@thecoursesubj~\@thecoursenumb: \@thecoursename}

      \vspace{1cm}
      \@theauthor

      \@theinstitute
      \vfill{}

      \@thecourseterm~\@thecourseyear

      \vspace{2in}
    \end{center}

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
}
