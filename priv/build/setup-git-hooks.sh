#!/bin/sh
# Install git hooks

CHECK_FORMAT="mix format --check-formatted"
WRITE_VERSION="git describe --tags --match "v*" | sed 's/^v//' | sed 's/-/+/2' > VERSION"

cat <<EOF > .git/hooks/pre-commit
#!/bin/sh
$CHECK_FORMAT
EOF

cat <<EOF > .git/hooks/post-commit
#!/bin/sh
$WRITE_VERSION
EOF

cat <<EOF > .git/hooks/post-checkout
#!/bin/sh
$WRITE_VERSION
EOF

cat <<EOF > .git/hooks/post-merge
#!/bin/sh
$WRITE_VERSION
EOF

cat <<EOF > .git/hooks/post-rewrite
#!/bin/sh
$WRITE_VERSION
EOF

chmod +x .git/hooks/pre-commit .git/hooks/post-commit .git/hooks/post-checkout .git/hooks/post-merge .git/hooks/post-rewrite
