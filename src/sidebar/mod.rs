use git2::Repository;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone)]
pub enum FileStatus {
    Normal,
    Modified,
    Staged,
    Untracked,
    Conflict,
}

#[derive(Debug, Clone)]
pub struct FileEntry {
    pub name: String,
    pub path: PathBuf,
    pub is_dir: bool,
    pub status: FileStatus,
    pub children: Vec<FileEntry>,
    pub expanded: bool,
}

impl FileEntry {
    pub fn new(name: String, path: PathBuf, is_dir: bool) -> Self {
        Self {
            name,
            path,
            is_dir,
            status: FileStatus::Normal,
            children: Vec::new(),
            expanded: false,
        }
    }
}

pub struct FileBrowser {
    root: PathBuf,
    entries: Vec<FileEntry>,
    show_hidden: bool,
}

impl FileBrowser {
    pub fn new(root: PathBuf) -> Self {
        let mut browser = Self {
            root,
            entries: Vec::new(),
            show_hidden: false,
        };
        browser.refresh();
        browser
    }

    pub fn set_root(&mut self, root: PathBuf) {
        self.root = root;
        self.refresh();
    }

    pub fn refresh(&mut self) {
        self.entries = self.load_directory(&self.root, 0);
    }

    fn load_directory(&self, path: &Path, depth: usize) -> Vec<FileEntry> {
        if depth > 3 {
            return Vec::new();
        }

        let mut entries = Vec::new();

        if let Ok(dir) = fs::read_dir(path) {
            let mut items: Vec<_> = dir.filter_map(|e| e.ok()).collect();
            items.sort_by(|a, b| {
                let a_is_dir = a.file_type().map(|t| t.is_dir()).unwrap_or(false);
                let b_is_dir = b.file_type().map(|t| t.is_dir()).unwrap_or(false);
                match (a_is_dir, b_is_dir) {
                    (true, false) => std::cmp::Ordering::Less,
                    (false, true) => std::cmp::Ordering::Greater,
                    _ => a.file_name().cmp(&b.file_name()),
                }
            });

            for entry in items {
                let name = entry.file_name().to_string_lossy().to_string();

                if !self.show_hidden && name.starts_with('.') {
                    continue;
                }

                let path = entry.path();
                let is_dir = entry.file_type().map(|t| t.is_dir()).unwrap_or(false);

                let mut file_entry = FileEntry::new(name, path.clone(), is_dir);

                if is_dir {
                    file_entry.children = self.load_directory(&path, depth + 1);
                }

                entries.push(file_entry);
            }
        }

        entries
    }

    pub fn toggle_show_hidden(&mut self) {
        self.show_hidden = !self.show_hidden;
        self.refresh();
    }

    pub fn entries(&self) -> &[FileEntry] {
        &self.entries
    }

    pub fn toggle_expand(&mut self, path: &Path) {
        toggle_expand_impl(&mut self.entries, path);
    }
}

fn toggle_expand_impl(entries: &mut Vec<FileEntry>, path: &Path) -> bool {
    for entry in entries.iter_mut() {
        if entry.path == path {
            entry.expanded = !entry.expanded;
            return true;
        }
        if entry.is_dir && toggle_expand_impl(&mut entry.children, path) {
            return true;
        }
    }
    false
}

pub struct GitIntegration {
    repo: Option<Repository>,
    branch: String,
    status: Vec<(PathBuf, FileStatus)>,
    is_git_repo: bool,
}

impl GitIntegration {
    pub fn new() -> Self {
        Self {
            repo: None,
            branch: String::new(),
            status: Vec::new(),
            is_git_repo: false,
        }
    }

    pub fn set_path(&mut self, path: &Path) {
        self.repo = Repository::discover(path).ok();

        if let Some(repo) = &self.repo {
            self.is_git_repo = true;

            self.branch = repo
                .head()
                .ok()
                .and_then(|h| h.shorthand().map(String::from))
                .unwrap_or_else(|| "HEAD".to_string());

            self.status = self.get_status_internal(repo);
        } else {
            self.is_git_repo = false;
            self.branch.clear();
            self.status.clear();
        }
    }

    fn get_status_internal(&self, repo: &Repository) -> Vec<(PathBuf, FileStatus)> {
        let mut statuses = Vec::new();

        if let Ok(statuses_iter) = repo.statuses(None) {
            for entry in statuses_iter.iter() {
                let path = entry.path().map(PathBuf::from).unwrap_or_default();
                let status = entry.status();

                let file_status = if status.is_index_new() || status.is_wt_new() {
                    FileStatus::Untracked
                } else if status.is_index_modified() || status.is_wt_modified() {
                    FileStatus::Modified
                } else if status.is_index_deleted() || status.is_wt_deleted() {
                    FileStatus::Modified
                } else if status.is_index_renamed() {
                    FileStatus::Staged
                } else if status.is_conflicted() {
                    FileStatus::Conflict
                } else {
                    FileStatus::Normal
                };

                statuses.push((path, file_status));
            }
        }

        statuses
    }

    pub fn is_git_repo(&self) -> bool {
        self.is_git_repo
    }

    pub fn branch(&self) -> &str {
        &self.branch
    }

    pub fn file_status(&self, path: &Path) -> FileStatus {
        for (p, status) in &self.status {
            if p == path {
                return status.clone();
            }
        }
        FileStatus::Normal
    }

    pub fn refresh(&mut self) {
        if let Some(repo) = &self.repo {
            self.status = self.get_status_internal(repo);
        }
    }

    pub fn get_status_summary(&self) -> (usize, usize, usize, usize) {
        let mut modified = 0;
        let mut staged = 0;
        let mut untracked = 0;
        let mut conflict = 0;

        for (_, status) in &self.status {
            match status {
                FileStatus::Modified => modified += 1,
                FileStatus::Staged => staged += 1,
                FileStatus::Untracked => untracked += 1,
                FileStatus::Conflict => conflict += 1,
                FileStatus::Normal => {}
            }
        }

        (modified, staged, untracked, conflict)
    }
}

pub struct Sidebar {
    pub file_browser: FileBrowser,
    pub git: GitIntegration,
    visible: bool,
    width: u32,
}

impl Sidebar {
    pub fn new(root: PathBuf) -> Self {
        let mut git = GitIntegration::new();
        git.set_path(&root);

        Self {
            file_browser: FileBrowser::new(root),
            git,
            visible: true,
            width: 250,
        }
    }

    pub fn toggle(&mut self) {
        self.visible = !self.visible;
    }

    pub fn show(&mut self) {
        self.visible = true;
    }

    pub fn hide(&mut self) {
        self.visible = false;
    }

    pub fn is_visible(&self) -> bool {
        self.visible
    }

    pub fn set_width(&mut self, width: u32) {
        self.width = width;
    }

    pub fn width(&self) -> u32 {
        self.width
    }

    pub fn update_cwd(&mut self, cwd: PathBuf) {
        self.file_browser.set_root(cwd.clone());
        self.git.set_path(&cwd);
    }

    pub fn refresh(&mut self) {
        self.file_browser.refresh();
        self.git.refresh();
    }
}
