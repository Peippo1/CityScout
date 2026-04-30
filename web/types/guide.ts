export interface GuideMessageRequest {
  destination: string;
  message: string;
  context: string[];
}

export interface GuideMessageResponse {
  request_id?: string;
  destination: string;
  reply: string;
  suggested_prompts: string[];
}
