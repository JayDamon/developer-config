return {
	(_G.llm == "copilot") and {
		"copilotlsp-nvim/copilot-lsp"
	} or nil,
	(_G.llm == "amazon-q") and {
		name = 'amazonq',
		url = 'ssh://git.amazon.com/pkg/AmazonQNVim',
		opts = {
			ssoStartUrl = 'https://amzn.awsapps.com/start',
		},
	} or nil,
}
