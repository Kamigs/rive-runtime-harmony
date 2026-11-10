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

import { File } from '../core/File';
import { FileAssetLoader } from '../core/FileAssetLoader';
import rive from 'libohos_rive.so';
import {
  ResourceId,
  ResourceUrl,
  ResourceBytes,
  ResourceRiveFile,
  ResourceType
} from '../renderers/RendererAttributes';
import { HttpService } from './HttpService';
import { FileCache } from './FileCache';

const TAG: string = 'FileFetcher';

/**
 * Unified `.riv` resolver.
 *
 * Collapses the view's previously-three-way loading (rawfile/resourceId, network URL,
 * in-memory bytes) into one entry point that:
 *   1. Resolves the resource to its raw byte buffer — through {@link FileCache}, so a
 *      repeated resource (e.g. 200 list cells of the same `.riv`) is fetched/decoded
 *      from rawfile or network only once at the byte layer.
 *   2. Builds a fresh {@link File} (owning its own native object + {@link LifecycleScope})
 *      and hands ownership to the caller.
 *
 * Ownership contract: the returned File has refs == 1 and is owned by the caller. The
 * view's existing handshake (setRiveFile acquires → caller release) is preserved.
 */
export class FileFetcher {
  /**
   * Resolves `resource` to a {@link File}.
   *
   * - `resourceRiveFile`: returned as-is (caller already owns it).
   * - `resourceId`/rawfile: read from `context.resourceManager`, byte-cached.
   * - `resourceUrl`: downloaded via {@link HttpService}, byte-cached.
   * - `resourceBytes`: cached by content key.
   *
   * @param resource The resource descriptor.
   * @param rendererType Renderer type for the File.
   * @param assetLoader Optional asset loader (shared native loader) attached to the File.
   * @param context Required for rawfile/resourceId resolution.
   */
  static fetch(
    resource: ResourceType,
    rendererType: rive.RendererType,
    assetLoader: FileAssetLoader | null,
    context: Context | null
  ): Promise<File> {
    switch (resource.type) {
      case 'resourceRiveFile':
        return Promise.resolve((resource as ResourceRiveFile).value);

      case 'resourceUrl': {
        const url = (resource as ResourceUrl).value;
        return FileCache.getInstance()
          .getOrLoad(url, () => HttpService.fetchBytes(url))
          .then((buffer: ArrayBuffer) => FileFetcher.buildFile(buffer, rendererType, assetLoader));
      }

      case 'resourceBytes': {
        // In-memory bytes are already available, so there is no fetch cost to avoid.
        // Skip the byte cache entirely — a sampled-content key could collide across
        // distinct same-length buffers, and each view needs its own File anyway.
        const buffer = (resource as ResourceBytes).value;
        // Defer buildFile into a .then so a MalformedFileException thrown by the File
        // constructor becomes a rejected promise (handled by the caller's .catch)
        // rather than a synchronous throw out of fetch().
        return Promise.resolve().then(() => FileFetcher.buildFile(buffer, rendererType, assetLoader));
      }

      case 'resourceId': {
        const resourceId = (resource as ResourceId).value.toString();
        if (!context) {
          return Promise.reject(new Error(`${TAG}: resourceId requires a context for rawfile resolution`));
        }
        const rawfileName = resourceId.replace('@rawfile/', '');
        const key = `rawfile:${rawfileName}`;
        return FileCache.getInstance()
          .getOrLoad(key, () => FileFetcher.readRawFile(context, rawfileName))
          .then((buffer: ArrayBuffer) => FileFetcher.buildFile(buffer, rendererType, assetLoader));
      }

      default:
        return Promise.reject(new Error(`${TAG}: Unknown resource type: ${resource.type}`));
    }
  }

  private static buildFile(
    buffer: ArrayBuffer,
    rendererType: rive.RendererType,
    assetLoader: FileAssetLoader | null
  ): File {
    return new File(buffer, rendererType, assetLoader);
  }

  /**
   * Reads a rawfile into an ArrayBuffer. The resource manager hands back a Uint8Array
   * that may be a view into a larger buffer, so slice out an independent copy.
   */
  private static readRawFile(context: Context, fileName: string): Promise<ArrayBuffer> {
    return new Promise<ArrayBuffer>((resolve, reject) => {
      context.resourceManager.getRawFileContent(fileName, (error, value: Uint8Array) => {
        if (error != null) {
          reject(new Error(`Failed to read rawfile ${fileName}: ${error}`));
          return;
        }
        const buffer = value.buffer.slice(value.byteOffset, value.byteOffset + value.byteLength);
        resolve(buffer);
      });
    });
  }
}
