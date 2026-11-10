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

/**
 * A queued state-machine input change. Producers (e.g. the view's input helpers)
 * build these and hand them to {@link RiveFileController.queueInputs}, which
 * flushes them into the matching {@link StateMachineInstance} during the next
 * advance.
 *
 * Lives in `core/` (rather than `controllers/`) so both the view and the
 * controller can import it without creating a layering cycle.
 */
export class ChangedInput {
  public stateMachineName: string;
  public name: string;
  public value: boolean | number | null;
  public nestedArtboardPath: string | null;

  constructor(
    stateMachineName: string,
    name: string,
    value: boolean | number | null = null,
    nestedArtboardPath: string | null = null
  ) {
    this.stateMachineName = stateMachineName;
    this.name = name;
    this.value = value;
    this.nestedArtboardPath = nestedArtboardPath;
  }
}
