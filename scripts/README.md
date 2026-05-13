# Scripts

Implementation scripts live here.

The top-level user interface is the repo `Makefile`. Scripts contain the actual
logic behind each command.

Current structure:

```text
scripts/
├── lib/
│   ├── checks.sh
│   ├── config.sh
│   ├── aws.sh
│   └── log.sh
├── local/
│   ├── aws-login.sh
│   ├── aws-whoami.sh
│   ├── configure-aws-sso.sh
│   ├── doctor.sh
│   └── init-config.sh
├── ec2/
│   ├── configure-ssh.sh
│   ├── instance-status.sh
│   ├── instances.sh
│   ├── launch-instance.sh
│   ├── reboot-instance.sh
│   ├── start-instance.sh
│   ├── stop-instance.sh
│   └── terminate-instance.sh
├── ebs/
│   ├── attach-volume.sh
│   ├── create-volume.sh
│   └── volumes.sh
├── remote/
│   ├── install-micromamba.sh
│   ├── mount-scratch.sh
│   ├── restore-dotfiles.sh
│   ├── save-dotfiles.sh
│   ├── scratch-common.sh
│   └── setup-scratch.sh
└── ssh/
    ├── add-ssh-rule.sh
    ├── create-key.sh
    ├── create-security-group.sh
    ├── import-key.sh
    └── ssh-status.sh
```
