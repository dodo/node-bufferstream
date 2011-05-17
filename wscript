from os.path import dirname

top = "."
out = "build"

class Dummy: pass


def configure(ctx):
    ctx.find_program("coffee", var="COFFEE")
    ctx.env.ARGS = "-co"


def build(ctx):
    env = Dummy()
    env.variant = lambda: ""
    for file in ctx.path.find_dir("src").ant_glob("**/*.coffee", flat=False):
        tgtpath = file.change_ext(".js").bldpath(env)[5:]
        ctx.path.exclusive_build_node(tgtpath)
        ctx(name   = "coffee",
            rule   = "${COFFEE} ${ARGS} default/%s ${SRC}" % dirname(tgtpath),
            source = file.srcpath()[3:],
            target = tgtpath)
