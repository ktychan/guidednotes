# % assume textarea is 7in wide
tex = lambda n: "\n".join([
    r'\documentclass[tikz]{standalone}',
    r'\begin{document}',
    r'\begin{tikzpicture}[x=0.175in, y=0.175in]',
    r'  \foreach \x in {0,1,...,40}',
    r'  {',
    f'    \\foreach \\y in {{0,1,...,{n}}}',
    r'    {',
    r'      \fill[gray!40] (\x, \y) circle[radius=0.5pt];',
    r'    }',
    r'  }',
    r'\end{tikzpicture}',
    r'\end{document}'
])

for n in range(1, 60+1):
    with open(f"grid_{n}_by_40.tex", 'w') as f:
        f.write(tex(n))
