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
  \def\@thecourseterm{#1}
  \def\@thecourseyear{#2}
  \def\@thecoursebreak{#3}
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

% subfiles
% \RequirePackage{refcount}
% \RequirePackage{xr}
\RequirePackage{xpatch}
\RequirePackage{standalone}
\RequirePackage{subfiles}

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
  \fancyhead[OL, ER]{\small \@thecoursesubj~\@thecoursenumb~(\@thecourseterm~\@thecourseyear)}
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
\surroundwithmdframed[style=simple-compact]{thm}
\surroundwithmdframed[style=simple-compact]{definition}
\surroundwithmdframed[style=simple-compact]{method}

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

  % befor code
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

\newcommand{\blanklinesfill}[1][\medskipamount]{
  \setlength\vremaining{\dimexpr\textheight - \pagetotal\relax}
  \blanklines[#1]{\directlua{calc_remaining_lines()}}
  \vfill{}
}

\newcommand{\blanklines}[2][\medskipamount]{
  \vspace{#1}
  \centerline{ \includegraphics{./standalones/grid_#2_by_40} }
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

    \phantom{top}\hfill{}\includegraphics[width=3in]{./WesternU.png}
    \begin{center}
      % title
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
