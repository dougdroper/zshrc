# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="1337"
ZSH_THEME_FILE=~/.oh-my-zsh/themes/1337.zsh-theme
ZSH_THEME_URL=https://raw.github.com/gist/9eec88fb06da5ce80ce6/fc0852483d04f54dabef8938c88aa17e8b8aaec1/1337.zsh-theme

test -f $ZSH_THEME_FILE || curl $ZSH_THEME_URL > $ZSH_THEME_FILE

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse vagrant)
plugins=(git github brew rvm gem osx bundler)

source $ZSH/oh-my-zsh.sh

# This loads RVM into a shell session.
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

# Customize to your needs...

export EDITOR="vim"

alias la='ll -a'
alias sc="script/console"
alias reload="touch tmp/restart.txt && (curl -I http://www.dev.notonthehighstreet.com)"
alias grc="git repack && git gc --aggressive"
alias t="touch tmp/restart.txt"
alias sub="open -a 'Sublime Text 2'"

if [ -x `which gitx` ]; then
  alias gk="gitx"
  alias gg="gitx --commit"
fi

rails=~/notonthehighstreet
deploy=~/Sites/noths/deploy
puppet=~/Sites/noths/puppet
config=~/Sites/noths/config

function __git_branch {
	local b="$(git symbolic-ref HEAD 2>/dev/null)"
  if [ -n "$b" ]; then
    printf "%s" "${b##refs/heads/}"
  fi
}

function pull {
  git pull origin `__git_branch`
}

function forward {
  git merge origin/`__git_branch`
}


function push {
  local pull=1
  local cjob=0
  local rebased=0
  local pull_opts=""
  local branch=`git branch | grep '^\*' | cut -f2 -d' '`
  local force=0

  for option in $*; do
    test $option = "--new" && pull=0
    test $option = "--hudson" && cjob=1
    test $option = "--rebase" && pull_opts=" --rebase"
    test $option = "--rebased" && rebased=1
    test $option = "--force" && force=1
  done

  if [ $rebased = 1 ]; then
    git push origin :$branch
    pull=0
  fi

  if [ $pull = 1 -a $force = 0 ]; then
    git pull $pull_opts origin `__git_branch`
  fi

  if [ $? = 0 ]; then
    if [ $force = 1 ]; then
      git push origin `__git_branch` --force
    else
      git push origin `__git_branch`
    fi
  fi

  if [ $? = 0 -a $cjob = 1 ]; then
    script/hudson create $branch
  fi
}

function delete_branch {
  branch=$1

  local flag="-d"
  local djob=0
  local remote=0
  local dir=`pwd`

  for option in $*; do
    test $option = "--force" && flag="-D"
    test $option = "--hudson" && djob=1
  done

  echo "Removing local branch"
  git branch $flag $branch
  echo "Removing remote branch"
  git push origin :$branch
  echo "Cleaning up rails repository"
  git remote prune origin

  if [ $djob = 1 ]; then
    echo "Removing hudson job"
    script/hudson delete $branch || true
  fi
}
