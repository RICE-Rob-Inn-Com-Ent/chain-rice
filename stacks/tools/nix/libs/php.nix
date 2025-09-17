{ pkgs }:

{
  packages = with pkgs; [
    # PHP runtime and package manager
    php83
    composer

    # Common PHP extensions
    php83Extensions.curl
    php83Extensions.mbstring
    php83Extensions.pdo
    php83Extensions.pdo_mysql
    php83Extensions.pdo_pgsql
    php83Extensions.sqlite3
    php83Extensions.json
    php83Extensions.xml
    php83Extensions.dom
    php83Extensions.simplexml
    php83Extensions.tokenizer
    php83Extensions.zip
    php83Extensions.opcache
    php83Extensions.gd
    php83Extensions.openssl
    php83Extensions.bcmath
    php83Extensions.intl
    php83Extensions.redis

    # Web SAPIs (for dev server/NGINX+PHP-FPM setups)
    php83Packages.php-cgi
    php83Packages.php-fpm

    # QA and tooling
    php83Packages.phpunit
    php83Packages.phpstan
    php83Packages.php-cs-fixer
    php83Packages.psysh

    # Databases and services (clients)
    postgresql
    mysql
    sqlite
    redis

    # Frontend toolchain for Laravel Vite
    nodejs_22
    nodePackages.yarn
    nodePackages.pnpm

    # Utilities
    git
    curl
    unzip
    zip
    jq
    ripgrep
    fd
    nginx
  ];
  
  envVars = {
    # Composer configuration
    COMPOSER_HOME = "$HOME/.composer";
    COMPOSER_ALLOW_SUPERUSER = "1";
    COMPOSER_NO_INTERACTION = "1";

    # PHP configuration
    PHP_MEMORY_LIMIT = "512M";
    PHP_DISPLAY_ERRORS = "1";

    # Project root hint
    CHAINRICE_PHP_ROOT = "$PWD/stacks/langs/php";
  };
  
  shellHook = ''
    echo "🐘 PHP $(php -v | head -n1)"
    echo "   • Composer $(composer --version 2>/dev/null | head -n1)"
    echo "   • Laravel tooling (installer/Sail) and Vite (Node) ready"

    # Ensure composer global bin and local node bin are on PATH
    export PATH="$HOME/.composer/vendor/bin:$PATH"
    if [ -d "node_modules/.bin" ]; then
      export PATH="node_modules/.bin:$PATH"
    fi

    # Install dependencies if composer.json exists
    if [ -f "composer.json" ]; then
      echo "📦 composer install"
      composer install --no-interaction --prefer-dist || true
    fi

    # Install Laravel installer globally if missing
    if ! command -v laravel >/dev/null 2>&1; then
      echo "🧰 Installing laravel/installer globally"
      composer global require laravel/installer --no-interaction || true
    fi

    # Laravel project helpers
    alias artisan='php artisan'
    alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'
    alias lnew='laravel new'
    alias lserve='php artisan serve --host 0.0.0.0 --port 8000'
    alias lvite='vite || npm run dev || yarn dev || pnpm dev'

    # Show Laravel version if in a Laravel project
    if [ -f "artisan" ] || grep -q '"laravel/framework"' composer.json 2>/dev/null; then
      php artisan --version || true
      # If APP_KEY not set and .env exists, generate it
      if [ -f ".env" ] && ! grep -q "^APP_KEY=\w" .env; then
        php artisan key:generate || true
      fi
    fi

    # Helpful aliases
    alias punit='phpunit'
    alias pstan='phpstan analyze'
    alias pcsf='php-cs-fixer fix'
    alias pserve='php -S 0.0.0.0:8000 -t public'
    alias pfpm='php-fpm -F'

    # NGINX quick config (if desired)
    alias nginx-start='nginx -g "daemon off;"'

    # PsySH REPL
    alias psysh='psysh'

    # Sample project hint
    if [ -f "${CHAINRICE_PHP_ROOT}/composer.json" ]; then
      echo "📘 Sample available at ${CHAINRICE_PHP_ROOT}"
      echo "   (cd ${CHAINRICE_PHP_ROOT} && composer install && php -S 0.0.0.0:8000 -t public)"
    fi
  '';
}
