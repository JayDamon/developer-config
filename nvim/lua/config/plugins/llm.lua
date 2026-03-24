return {
	(_G.llm == "copilot") and {
		"github/copilot.vim",
		version = "v1.34.0",
	} or nil,
	(_G.llm == "amazon-q") and {
		name = 'amazonq',
		url = 'ssh://git.amazon.com/pkg/AmazonQNVim',
		opts = {
			ssoStartUrl = 'https://amzn.awsapps.com/start',
		},
	} or nil,
}
