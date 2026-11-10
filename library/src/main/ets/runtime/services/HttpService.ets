/*
 * Copyright (C) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import http from '@ohos.net.http';

const TAG: string = 'HttpService';

/**
 * Shared HTTP byte fetcher.
 *
 * Collapses the three previously-duplicated `http.createHttp().request(...)` blocks
 * (file download in {@link FileFetcher}, CDN asset fetch in CDNAssetLoader, and the
 * demo's RandomNetworkLoader) behind one implementation with consistent timeouts and
 * error handling. Each call still creates and destroys its own {@link http.HttpRequest}
 * (the HarmonyOS http API is one-shot), but the request/response/error shape is uniform.
 */
export class HttpService {
  /**
   * Downloads `url` and resolves with its body as an {@link ArrayBuffer}.
   *
   * Rejects on non-200, empty body, or transport failure.
   *
   * @param url Absolute URL to GET.
   * @param connectTimeoutMs Connect timeout in ms (default 60s).
   * @param readTimeoutMs Read timeout in ms (default 60s).
   */
  static fetchBytes(
    url: string,
    connectTimeoutMs: number = 60000,
    readTimeoutMs: number = 60000
  ): Promise<ArrayBuffer> {
    return new Promise<ArrayBuffer>((resolve, reject) => {
      const httpRequest = http.createHttp();
      httpRequest
        .request(url, {
          method: http.RequestMethod.GET,
          connectTimeout: connectTimeoutMs,
          readTimeout: readTimeoutMs,
          expectDataType: http.HttpDataType.ARRAY_BUFFER
        })
        .then((response) => {
          if (response.responseCode !== 200) {
            reject(new Error(`HTTP ${response.responseCode} for ${url}`));
            return;
          }
          const result = response.result;
          if (!(result instanceof ArrayBuffer) || result.byteLength === 0) {
            reject(new Error(`Empty or non-ArrayBuffer response from ${url}`));
            return;
          }
          resolve(result);
        })
        .catch((error: Error) => {
          reject(new Error(`Request failed for ${url}: ${error}`));
        })
        .finally(() => {
          httpRequest.destroy();
        });
    });
  }
}
