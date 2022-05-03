/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.accumulo.testing.continuous;

import org.apache.accumulo.core.client.AccumuloClient;
import org.apache.accumulo.core.client.Scanner;
import org.apache.accumulo.core.client.ScannerBase.ConsistencyLevel;
import org.apache.accumulo.core.client.TableNotFoundException;
import org.apache.accumulo.core.security.Authorizations;
import org.apache.accumulo.testing.TestProps;

/**
 * Useful utility methods common to the Continuous test suite.
 
final class ContinuousUtil {
  private ContinuousUtil() {}

  /**
   * Attempt to create a table scanner, or fail if the table does not exist.
   *
   * @param client
   *          A populated AccumuloClient object
   * @param table
   *          The table name to scan over
   * @param auths
   *          The authorizations to use for the scanner
   * @return a scanner for the requested table
   * @throws TableNotFoundException
   *           If the table does not exist
   */
  static Scanner createScanner(AccumuloClient client, ContinuousEnv env, Authorizations auths)
      throws TableNotFoundException {
    String table = env.getAccumuloTableName();

    ConsistencyLevel cLevel = ConsistencyLevel.valueOf(env.getTestProperty(TestProps.CI_SCANNER_CONSISTENCY).toUpperCase());

    if (!client.tableOperations().exists(table)) {
      throw new TableNotFoundException(null, table,
          "Consult the README and create the table before starting test processes.");
    }
    var scanner = client.createScanner(table, auths);
    scanner.setConsistencyLevel(cLevel);
    return scanner;
  }
}
