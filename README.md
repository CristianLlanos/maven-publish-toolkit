# Maven Publish Toolkit

Publish Kotlin/Gradle packages to Maven Central from macOS — without secrets on disk.

One script sets up your machine. Another publishes your project. All credentials live in macOS Keychain.

## The problem

Publishing to Maven Central requires a surprising amount of setup: GPG keys, keyserver registration, Sonatype credentials, Gradle signing configuration, and a plugin that actually knows how to talk to the Central Portal API. It's easy to get wrong, hard to remember, and painful to repeat on a new machine.

## What this does

**`setup-maven-publishing`** runs once per machine and handles everything:

- Installs GPG and `pinentry-mac` via Homebrew
- Configures the GPG agent to cache passphrases in macOS Keychain
- Imports your GPG keys (or generates new ones)
- Publishes your public key to a keyserver
- Stores your Central Portal credentials in Keychain
- Configures Gradle for artifact signing

**`publish-maven`** runs from any Gradle project:

```bash
publish-maven            # publish to Maven Central
publish-maven --dry-run  # publish to ~/.m2 only (test everything without uploading)
```

No passwords in `gradle.properties`. No tokens in environment variables. No secrets in shell history.

## Quick start

### 1. Install the toolkit

```bash
git clone https://github.com/CristianLlanos/maven-publish-toolkit.git
cd maven-publish-toolkit
make install
```

### 2. Set up your machine

```bash
setup-maven-publishing
```

The script is interactive and idempotent — it detects what's already configured and skips those steps. You'll need:

- A [Central Portal](https://central.sonatype.com) account with a [verified namespace](https://central.sonatype.org/register/namespace/)
- A Central Portal [user token](https://central.sonatype.com/account) (username + password pair)
- GPG keys — bring your own or let the script generate them

If you have exported GPG keys, place them at `~/.config/keys/gpg/` (the default) or specify a custom path:

```bash
setup-maven-publishing --keys-dir /path/to/your/keys
```

Expected files: `private-key.gpg` and `public-key.gpg`.

### 3. Configure your project

Add the [Vanniktech Maven Publish](https://github.com/vanniktech/gradle-maven-publish-plugin) plugin to your `build.gradle.kts`:

```kotlin
plugins {
    kotlin("jvm") version "1.9.25"
    signing
    id("com.vanniktech.maven.publish") version "0.30.0"
}

signing {
    useGpgCmd()
}

mavenPublishing {
    publishToMavenCentral(com.vanniktech.maven.publish.SonatypeHost.CENTRAL_PORTAL)
    signAllPublications()

    coordinates("com.example", "your-artifact", version.toString())

    pom {
        name.set("Your Project Name")
        description.set("A description of your project")
        url.set("https://github.com/you/your-project")

        licenses {
            license {
                name.set("MIT License")
                url.set("https://opensource.org/licenses/MIT")
            }
        }

        developers {
            developer {
                id.set("your-id")
                name.set("Your Name")
                email.set("you@example.com")
            }
        }

        scm {
            connection.set("scm:git:git://github.com/you/your-project.git")
            developerConnection.set("scm:git:ssh://github.com/you/your-project.git")
            url.set("https://github.com/you/your-project")
        }
    }
}
```

If you forget this step, `publish-maven` will print the template for you.

### 4. Publish

```bash
cd your-project

# Verify everything works locally first
publish-maven --dry-run

# Ship it
publish-maven
```

## How it works

The toolkit uses two security mechanisms to avoid storing secrets in files:

**GPG signing** is handled by the system GPG agent, which uses `pinentry-mac` to prompt for the passphrase and cache it in macOS Keychain. Gradle's `useGpgCmd()` delegates signing to this agent — no passphrase in `gradle.properties`.

**Central Portal credentials** are stored in macOS Keychain and retrieved at publish time via the `security` CLI. They're passed to Gradle as `-P` flags, which don't appear in shell history or process listings.

### Where things are stored

| Secret | Storage | How it's used |
|---|---|---|
| Central Portal username | Keychain (`central-portal` / `username`) | Passed to Gradle via `-P` at publish time |
| Central Portal password | Keychain (`central-portal` / `password`) | Passed to Gradle via `-P` at publish time |
| GPG passphrase | Keychain (via `pinentry-mac`) | GPG agent retrieves it automatically when signing |
| Signing key ID | `~/.gradle/gradle.properties` | Tells Gradle which GPG key to sign with (not a secret) |
| GPG agent config | `~/.gnupg/gpg-agent.conf` | Points GPG to `pinentry-mac` for Keychain integration |

## Setting up a new machine

This is the whole point of the toolkit. On a fresh Mac:

1. Install Homebrew
2. Clone this repo and `make install`
3. Copy your GPG keys to `~/.config/keys/gpg/` (or a USB drive)
4. Run `setup-maven-publishing`
5. You're ready to publish

## Uninstall

```bash
make uninstall
```

This removes the scripts from `~/bin`. Keychain entries, GPG keys, and Gradle configuration are left untouched.

## Requirements

- macOS (Apple Silicon or Intel)
- Homebrew
- Gradle (in each project you want to publish)
