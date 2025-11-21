"""
开发者请自行修改所有配置。AUDIO_API_KEY和OPENROUTER_API_KEY的如果留空，则默认使用CORE_API_KEY。
如果core_config.txt中的coreApiKey被修改，则会在启动时自动覆盖CORE_API_KEY。
"""
# Constant for servers
OPENROUTER_URL = "https://dashscope.aliyuncs.com/compatible-mode/v1"#"https://openrouter.ai/api/v1"
CORE_URL = "wss://open.bigmodel.cn/api/paas/v4/realtime"#"wss://dashscope.aliyuncs.com/api-ws/v1/realtime"#wss://api.openai.com/v1/realtime
CORE_MODEL = "glm-realtime-air"#"qwen-omni-turbo-realtime-2025-05-08"#gpt-4o-realtime-preview

MAIN_SERVER_PORT = 48911
MEMORY_SERVER_PORT = 48912
MONITOR_SERVER_PORT = 48913
COMMENTER_SERVER_PORT = 48914
CORE_API_KEY = ''
AUDIO_API_KEY = OPENROUTER_API_KEY = ''

# Variable for models
ROUTER_MODEL = 'openai/gpt-4.1'
SUMMARY_MODEL = "qwen-plus" #'openai/gpt-4.1'
SETTING_PROPOSER_MODEL = "qwen-max"#'openai/gpt-4.1'
SETTING_VERIFIER_MODEL = "qwen-max"#'openai/o4-mini'
SEMANTIC_MODEL = 'text-embedding-v4'
RERANKER_MODEL = 'qwen-plus'#'openai/gpt-4.1'
CORRECTION_MODEL = 'qwen3-235b-a22b'#'openai/gpt-4.1'
EMOTION_MODEL = 'qwen-turbo'