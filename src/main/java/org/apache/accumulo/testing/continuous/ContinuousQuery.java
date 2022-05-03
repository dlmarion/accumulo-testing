package org.apache.accumulo.testing.continuous;

import com.google.common.base.Preconditions;
import org.apache.accumulo.core.client.AccumuloClient;
import org.apache.accumulo.core.client.Scanner;
import org.apache.accumulo.core.data.Key;
import org.apache.accumulo.core.data.Range;
import org.apache.accumulo.core.data.Value;
import org.apache.accumulo.core.security.Authorizations;
import org.apache.accumulo.testing.TestProps;
import org.apache.hadoop.io.Text;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.Iterator;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.TimeUnit;

import static com.google.common.util.concurrent.Uninterruptibles.sleepUninterruptibly;
import static java.nio.charset.StandardCharsets.UTF_8;

public class ContinuousQuery {
  private static final Logger log = LoggerFactory.getLogger(ContinuousScanner.class);

  public static void main(String[] args) throws Exception {

    try (ContinuousEnv env = new ContinuousEnv(Arrays.copyOfRange(args,2, args.length))) {

      Random r = new Random();

      int scannerSleepMs = Integer.parseInt(env.getTestProperty(TestProps.CI_SCANNER_SLEEP_MS));

      long startPrefix = Long.parseLong(args[0], 16);
      long endPrefix = Long.parseLong(args[1], 16);

      startPrefix = startPrefix << Long.numberOfLeadingZeros(startPrefix);
      endPrefix = endPrefix << Long.numberOfLeadingZeros(endPrefix);

      Preconditions.checkArgument(startPrefix < endPrefix);

      long startMask = -1L >>> (64 - Long.numberOfTrailingZeros(startPrefix));
      long endMask = -1L >>> (64 - Long.numberOfTrailingZeros(startMask));

      System.out.printf("Start Prefix : 0x%016x\n", startPrefix);
      System.out.printf("Start Mask   : 0x%016x\n", startMask);
      System.out.printf("End Prefix   : 0x%016x\n", endPrefix);
      System.out.printf("End Mask     : 0x%016x\n", endMask);

      AccumuloClient client = env.getAccumuloClient();
      Authorizations auths = env.getRandomAuthorizations();
      Scanner scanner = ContinuousUtil.createScanner(client, env, auths);

      while(true){
        long startRow = ContinuousIngest.genLong(env.getRowMin(), env.getRowMax(), r);
        startRow = startRow & startMask | startPrefix;

        long endRow = ContinuousIngest.genLong(env.getRowMin(), env.getRowMax(), r);
        endRow = endRow & endMask | endPrefix;

        while(endRow <= startRow) {
          endRow = ContinuousIngest.genLong(env.getRowMin(), env.getRowMax(), r);
          endRow = endRow & endMask | endPrefix;
        }

        byte[] scanStart = ContinuousIngest.genRow(startRow);
        byte[] scanStop = ContinuousIngest.genRow(endRow);

        scanner.setRange(new Range(new Text(scanStart), new Text(scanStop)));

        int count = 0;
        Iterator<Map.Entry<Key,Value>> iter = scanner.iterator();

        long t1 = System.currentTimeMillis();

        while (iter.hasNext()) {
          Map.Entry<Key,Value> entry = iter.next();
          ContinuousWalk.validate(entry.getKey(), entry.getValue());
          count++;
        }

        long t2 = System.currentTimeMillis();

        log.debug("SCN {} {} {} {}", t1, new String(scanStart, UTF_8), (t2 - t1), count);

        if (scannerSleepMs > 0) {
          sleepUninterruptibly(scannerSleepMs, TimeUnit.MILLISECONDS);
        }

      }
    }
  }

}
