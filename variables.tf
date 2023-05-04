variable "name"{
    type = string 
    description = "Name to be used on all the resources as identifier."
}

variable "description"{
    type = string 
    description = "A description for the Codebuild project."
    default = "CodeBuild project"
}

variable "github_repository"{
    type = string 
    description = "Github repository URL, the repository's events will trigger the CodeBuild."
}

variable "branch"{
    type = string 
    description = "Name of the branch which will be used as a trigger (according to the event)."
}

variable "github_event"{
    type = string
    description = "The event that triggers the Codebuild project."
    default = "PUSH"

    validation {
    condition     = can(regex("^(PUSH|PULL_REQUEST_CREATED|PULL_REQUEST_UPDATED|PULL_REQUEST_REOPENED|PULL_REQUEST_MERGED)$", var.github_event))
    error_message = "Must be one of these events: PUSH, PULL_REQUEST_CREATED, PULL_REQUEST_UPDATED, PULL_REQUEST_REOPENED. PULL_REQUEST_MERGED."
  }
}

variable "environment_variables"{
    type = map(string)
    description = "Environment variables for the CodeBuild project."
    default = {}
}

variable "buildspec_file" {
     type = string
     description = "The path for the buildspec.yaml file."
 }

 variable "codebuild_compute_type" {
    type = string
    description = "Information about the compute resources the build project will use."
    default = "BUILD_GENERAL1_SMALL"

    validation {
        condition = can(regex("^(BUILD_GENERAL1_SMALL|BUILD_GENERAL1_MEDIUM|BUILD_GENERAL1_LARGE|BUILD_GENERAL1_2XLARGE)$", var.codebuild_compute_type))
        error_message = "Must be one of these types: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM, BUILD_GENERAL1_LARGE, BUILD_GENERAL1_2XLARGE."
    }
}