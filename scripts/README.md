# wbtl.app Scripts

Scripts for managing wbtl.app tool repositories and deployments.

## Scripts

### setup-repo.sh

Creates a new tool repository in the wbtl-app GitHub organization.

**Usage:**
```bash
./scripts/setup-repo.sh <tool-name>
```

**Example:**
```bash
./scripts/setup-repo.sh timer
./scripts/setup-repo.sh json-format
./scripts/setup-repo.sh pdf-merge
```

**What it does:**
1. Validates the tool name (lowercase letters, numbers, dashes only)
2. Checks if the repo already exists on GitHub
3. Creates a new public repo at `github.com/wbtl-app/<tool-name>`
4. Creates local folder at `~/projects/wbtl-app/<tool-name>`
5. Initializes git with remote origin and pushes initial README
6. Copies template files locally (NOT committed):
   - `tool.html` - Base HTML template
   - `icon-guidelines.md` - Icon design reference
   - If matching specs exist in `experiment/tool-specs/`: `<tool-name>.md` and `<tool-name>.svg`

**Requirements:**
- GitHub CLI (`gh`) installed and authenticated
- Write access to the `wbtl-app` GitHub organization

---

### deploy-page.sh

Sets up Cloudflare Pages hosting for a wbtl.app tool.

**Usage:**
```bash
./path/to/deploy-page.sh --dist <folder> [--build <command>]
```

Run this from the root of your tool repository (not from the scripts folder).

**Examples:**
```bash
# Simple static site (no build step)
cd ~/projects/wbtl-app/timer
/home/chris/projects/wbtl-app/wbtl-app/scripts/deploy-page.sh --dist public

# With build step
cd ~/projects/wbtl-app/json-format
/home/chris/projects/wbtl-app/wbtl-app/scripts/deploy-page.sh --dist dist --build "npm run build"
```

**What it does:**
1. Verifies you're in a valid wbtl-app tool repository
2. Checks if a Cloudflare Pages project already exists
3. Creates a Pages project named `wbtl-app-<tool-name>`
4. Connects to your GitHub repo for automatic deployments
5. Sets up DNS CNAME record for `<tool-name>.wbtl.app`
6. Adds custom domain to the Pages project

**Options:**
| Option | Required | Description |
|--------|----------|-------------|
| `--dist`, `-d` | Yes | Distribution folder containing built files |
| `--build`, `-b` | No | Build command to run before deployment |

**Requirements:**
- Cloudflare account with API access
- Cloudflare API token with Pages and DNS permissions
- Environment variables configured (see below)

---

## Environment Variables

Create a `.env` file in this scripts folder with your credentials:

```bash
cp .env.example .env
# Edit .env with your values
```

### Required for deploy-page.sh

| Variable | Description | How to Get |
|----------|-------------|------------|
| `CLOUDFLARE_ACCOUNT_ID` | Your Cloudflare account ID | Dashboard URL: `dash.cloudflare.com/<account-id>` |
| `CLOUDFLARE_API_TOKEN` | API token with edit permissions | Create at: Account > API Tokens |
| `CLOUDFLARE_ZONE_ID` | Zone ID for wbtl.app domain | Domain Overview page in dashboard |

### Creating a Cloudflare API Token

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use "Edit Cloudflare Workers" template OR create custom with:
   - **Account** > Cloudflare Pages > Edit
   - **Zone** > DNS > Edit
   - **Zone** > Zone > Read (for wbtl.app)
4. Copy the token to your `.env` file

### Finding Your Account ID and Zone ID

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. **Account ID**: In the URL after logging in: `dash.cloudflare.com/<account-id>`
3. **Zone ID**: Click on wbtl.app domain > Overview > scroll down to "API" section

---

## Security Notes

- The `.env` file is git-ignored and should never be committed
- Keep your API token secret - it has write access to your Cloudflare resources
- The scripts only need to be run when setting up new tools
