#[derive(Debug, Clone)]
pub struct Context {
    pub working_directory: String,
    pub last_commands: Vec<String>,
    pub git_branch: Option<String>,
    pub project_type: Option<String>,
    pub shell: String,
}

impl Context {
    pub fn new(working_directory: String, shell: String) -> Self {
        Self {
            working_directory,
            last_commands: Vec::new(),
            git_branch: None,
            project_type: None,
            shell,
        }
    }

    pub fn with_git_branch(mut self, branch: String) -> Self {
        self.git_branch = Some(branch);
        self
    }

    pub fn with_project_type(mut self, project_type: String) -> Self {
        self.project_type = Some(project_type);
        self
    }

    pub fn add_command(mut self, command: String) -> Self {
        self.last_commands.push(command);
        if self.last_commands.len() > 10 {
            self.last_commands.remove(0);
        }
        self
    }

    pub fn to_prompt_context(&self) -> String {
        let mut context = format!(
            "Working directory: {}\nShell: {}\n",
            self.working_directory, self.shell
        );

        if let Some(branch) = &self.git_branch {
            context.push_str(&format!("Git branch: {}\n", branch));
        }

        if let Some(project_type) = &self.project_type {
            context.push_str(&format!("Project type: {}\n", project_type));
        }

        if !self.last_commands.is_empty() {
            context.push_str("Recent commands:\n");
            for cmd in &self.last_commands {
                context.push_str(&format!("  - {}\n", cmd));
            }
        }

        context
    }
}
