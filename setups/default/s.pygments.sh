.local/bin/pygmentize
#!/bin/bash
exec uv tool run --from pygments pygmentize "$@"
