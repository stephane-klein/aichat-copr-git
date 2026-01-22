# Dynamic variables - defined via rpmbuild --define by .copr/Makefile
# For local builds, you can set them manually or use the defaults below
%{!?upstream_version: %global upstream_version 0.30.0}
%{!?commitdate: %global commitdate 20260122}
%{!?commit0: %global commit0 236097b18478fd0714f6f207988a32663ccea155}
%{!?shortcommit0: %global shortcommit0 236097b}

Name:           aichat-git
Version:        %{upstream_version}+git%{commitdate}.%{shortcommit0}
Release:        1%{?dist}
Summary:        All-in-one LLM CLI tool featuring Shell Assistant, Chat-REPL, RAG, AI Tools & Agents (git version)

License:        MIT OR Apache-2.0
URL:            https://github.com/sigoden/aichat
Source0:        aichat-%{shortcommit0}.tar.gz

BuildRequires:  rust
BuildRequires:  cargo
BuildRequires:  gcc
BuildRequires:  openssl-devel

Conflicts:      aichat

%description
AIChat is an all-in-one LLM CLI tool featuring Shell Assistant, CMD & REPL Mode,
RAG, AI Tools & Agents. It integrates seamlessly with over 20 leading LLM providers
through a unified interface including OpenAI, Claude, Gemini, Ollama, and more.

This is the development version built from git commit %{shortcommit0} (%{commitdate}).

%prep
%autosetup -n aichat-%{commit0}

%build
cargo build --release

%install
install -Dm755 target/release/aichat %{buildroot}%{_bindir}/aichat

install -Dm644 scripts/completions/aichat.bash %{buildroot}%{_datadir}/bash-completion/completions/aichat
install -Dm644 scripts/completions/aichat.fish %{buildroot}%{_datadir}/fish/vendor_completions.d/aichat.fish
install -Dm644 scripts/completions/aichat.zsh %{buildroot}%{_datadir}/zsh/site-functions/_aichat

install -Dm644 README.md %{buildroot}%{_docdir}/%{name}/README.md
install -Dm644 config.example.yaml %{buildroot}%{_docdir}/%{name}/config.example.yaml

%files
%license LICENSE-MIT LICENSE-APACHE
%doc README.md
%{_bindir}/aichat
%{_datadir}/bash-completion/completions/aichat
%{_datadir}/fish/vendor_completions.d/aichat.fish
%{_datadir}/zsh/site-functions/_aichat
%{_docdir}/%{name}/

%changelog
* Thu Jan 22 2026 Stephane Klein <contact@stephane-klein.info> - %{version}-1
