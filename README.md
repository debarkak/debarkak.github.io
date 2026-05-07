# debarka's blog

my personal blog, nothing fancy. built with [hugo](https://gohugo.io/) and hosted on github pages. uses solarized colors and a monospace font because i like it that way. everything is lowercase because why not.

## how to use

theres 3 scripts that do everything for you:

### making a new post

```bash
./new-post.sh
```

it asks you what you wanna call the post, then makes a blank markdown file for you. just open it and write whatever you want — plain markdown, no special format needed. you dont need to add frontmatter or anything, the finalize script handles all of that.

### finalizing

```bash
./finalize.sh
```

run this when youre done writing. it goes through all your posts and:

- adds frontmatter if you didnt write any (title from the first `# heading`, date from the file, description from the first paragraph)
- fills in missing fields if you only wrote some frontmatter
- syncs everything to the preview folder
- rebuilds `posts.js`
- syncs css
- cleans up any orphaned files

basically it takes whatever you wrote and makes it ready.

### updating rss and stuff

```bash
./update-rss.sh
```

this one needs hugo installed. it builds the whole site and checks that the rss feed and sitemap got generated properly.

## search

theres a search bar on the homepage that filters posts as you type. it just searches through titles and descriptions, nothing fancy.

## previewing locally

the `preview/` folder works without hugo or anything, you can just open `preview/index.html` in firefox and itll work. if youre using chrome or something you need to run a quick server:

```bash
python3 -m http.server 8000
# then go to http://localhost:8000/preview/
```

## deploying

just push to `main` and github actions handles everything. it builds the site with hugo and deploys it to github pages at `https://debarkak.github.io/blog/`.

## font toggle

theres a `serif` button in the nav if the monospace font is hard to read, it switches to a nicer serif font (lora).

## whats in here

```text
.
├── new-post.sh            # makes a blank post file
├── finalize.sh            # organizes and syncs everything
├── update-rss.sh          # builds site, checks rss
├── hugo.toml
├── content/
│   ├── about.md
│   └── blog/              # posts go here
├── themes/minimal/        # the theme, made from scratch
│   ├── layouts/
│   └── static/css/
│       ├── main.css       # solarized light
│       └── dark.css       # solarized dark
├── preview/               # local preview, not deployed
│   ├── index.html
│   ├── about.html
│   ├── post.html
│   ├── posts.js           # managed by finalize.sh
│   ├── css/
│   └── posts/
└── .github/workflows/
    └── deploy.yml
```
