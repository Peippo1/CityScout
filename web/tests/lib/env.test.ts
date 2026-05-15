import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { validateServerEnv, getRequiredEnv, getOptionalEnv, envStatusSummary } from "@/lib/env";

describe("validateServerEnv", () => {
  const REQUIRED = [
    "CITYSCOUT_API_BASE_URL",
    "CITYSCOUT_APP_SHARED_SECRET",
    "NEXT_PUBLIC_SUPABASE_URL",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY"
  ];

  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it("returns valid when all required vars are present", () => {
    for (const name of REQUIRED) {
      process.env[name] = "test-value";
    }
    const result = validateServerEnv();
    expect(result.valid).toBe(true);
    expect(result.missing).toHaveLength(0);
    expect(result.present).toEqual(expect.arrayContaining(REQUIRED));
  });

  it("returns invalid when a required var is missing", () => {
    for (const name of REQUIRED) {
      process.env[name] = "test-value";
    }
    delete process.env["CITYSCOUT_API_BASE_URL"];
    const result = validateServerEnv();
    expect(result.valid).toBe(false);
    expect(result.missing).toContain("CITYSCOUT_API_BASE_URL");
  });

  it("returns invalid when a required var is empty string", () => {
    for (const name of REQUIRED) {
      process.env[name] = "test-value";
    }
    process.env["CITYSCOUT_APP_SHARED_SECRET"] = "   ";
    const result = validateServerEnv();
    expect(result.valid).toBe(false);
    expect(result.missing).toContain("CITYSCOUT_APP_SHARED_SECRET");
  });

  it("treats optional vars as not required", () => {
    for (const name of REQUIRED) {
      process.env[name] = "test-value";
    }
    delete process.env["SUPABASE_SERVICE_ROLE_KEY"];
    delete process.env["INTERNAL_ALLOWED_EMAILS"];
    const result = validateServerEnv();
    expect(result.valid).toBe(true);
  });
});

describe("getRequiredEnv", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it("returns the value when present", () => {
    process.env["TEST_VAR"] = "hello";
    expect(getRequiredEnv("TEST_VAR")).toBe("hello");
  });

  it("throws when the variable is missing", () => {
    delete process.env["TEST_VAR"];
    expect(() => getRequiredEnv("TEST_VAR")).toThrow("Missing required environment variable: TEST_VAR");
  });
});

describe("getOptionalEnv", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it("returns the value when present", () => {
    process.env["OPTIONAL_VAR"] = "value";
    expect(getOptionalEnv("OPTIONAL_VAR")).toBe("value");
  });

  it("returns undefined when missing", () => {
    delete process.env["OPTIONAL_VAR"];
    expect(getOptionalEnv("OPTIONAL_VAR")).toBeUndefined();
  });

  it("returns undefined for whitespace-only value", () => {
    process.env["OPTIONAL_VAR"] = "   ";
    expect(getOptionalEnv("OPTIONAL_VAR")).toBeUndefined();
  });
});

describe("envStatusSummary", () => {
  const REQUIRED = [
    "CITYSCOUT_API_BASE_URL",
    "CITYSCOUT_APP_SHARED_SECRET",
    "NEXT_PUBLIC_SUPABASE_URL",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY"
  ];

  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it("reports present for set vars and missing for unset", () => {
    for (const name of REQUIRED) {
      process.env[name] = "test-value";
    }
    delete process.env["CITYSCOUT_API_BASE_URL"];

    const summary = envStatusSummary();
    expect(summary["CITYSCOUT_API_BASE_URL"]).toBe("missing");
    expect(summary["CITYSCOUT_APP_SHARED_SECRET"]).toBe("present");
  });

  it("never includes secret values in output", () => {
    process.env["CITYSCOUT_APP_SHARED_SECRET"] = "super-secret-value";
    const summary = envStatusSummary();
    const asString = JSON.stringify(summary);
    expect(asString).not.toContain("super-secret-value");
  });
});
