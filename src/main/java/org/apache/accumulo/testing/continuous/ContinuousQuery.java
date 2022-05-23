package org.apache.accumulo.testing.continuous;

import org.apache.accumulo.core.client.AccumuloClient;
import org.apache.accumulo.core.client.Scanner;
import org.apache.accumulo.core.data.Key;
import org.apache.accumulo.core.data.Range;
import org.apache.accumulo.core.data.Value;
import org.apache.accumulo.core.security.Authorizations;
import org.apache.commons.math3.stat.descriptive.SummaryStatistics;
import org.apache.hadoop.io.Text;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;

import static com.google.common.util.concurrent.Uninterruptibles.sleepUninterruptibly;
import static java.nio.charset.StandardCharsets.UTF_8;

public class ContinuousQuery {
  private static final Logger log = LoggerFactory.getLogger(ContinuousScanner.class);

  private static class QueryResult {
    final long time;
    final int num;

    private QueryResult(long time, int num) {
      this.time = time;
      this.num = num;
    }
  }

  public static void main(String[] args) throws Exception {

    if(args.length < 5) {
      System.err.println("Usage : "+ContinuousQuery.class.getSimpleName()+" <min row> <max row> <prefix len> <threads> <total scans>");
      System.exit(-1);
    }

    try (ContinuousEnv env = new ContinuousEnv(Arrays.copyOfRange(args,5, args.length))) {

      Random r = new Random();

      int scannerSleepMs = 0;

      long min = Long.parseLong(args[0], 16) << (64 - args[0].length() * 4);

      long max = Long.parseLong(args[1], 16) << (64 - args[1].length() * 4);

      int prefixLen = Integer.parseInt(args[2]);
      long suffixMask = -1L >>> prefixLen;
      long prefixMask = -1L << (64 - prefixLen);

      int threads = Integer.parseInt(args[3]);

      AccumuloClient client = env.getAccumuloClient();
      Authorizations auths = env.getRandomAuthorizations();

      ExecutorService executor = Executors.newFixedThreadPool(threads+1);

      List<Future<?>> futures = new ArrayList<>();

      LinkedBlockingQueue<QueryResult> times = new LinkedBlockingQueue<>();

      SummaryStatistics timeSummaryStatistics = new SummaryStatistics();
      SummaryStatistics resultsSummaryStatistics = new SummaryStatistics();
      

      executor.submit(()->{
        List<QueryResult> fetched = new ArrayList<>();

        while(true){
          while(fetched.size() < 1000) {
            var qr = times.take();
            fetched.add(qr);
            timeSummaryStatistics.addValue(qr.time);
            resultsSummaryStatistics.addValue(qr.num);
          }

          var timeStats = fetched.stream().mapToLong(qr -> qr.time).summaryStatistics();
          var countStats = fetched.stream().mapToInt(qr -> qr.num).summaryStatistics();

          log.info("STATS count:{} minTime:{} maxTime:{} avgTime:{} minResults:{} maxResults:{} avgResults:{}",
              timeStats.getCount(), timeStats.getMin(), timeStats.getMax(), timeStats.getAverage(),
              countStats.getMin(), countStats.getMax(), countStats.getAverage());

          fetched.clear();
        }

      });

      int totalScans = Integer.parseInt(args[4]);

      AtomicInteger scansStarted = new AtomicInteger(0);

      for(int i = 0; i< threads; i++){
        Runnable runnable = ()->{
          try(Scanner scanner = ContinuousUtil.createScanner(client, env, auths)) {

            while (scansStarted.getAndIncrement() < totalScans) {
              long startRow = ContinuousIngest.genLong(min, max, r);

              long endRow = ContinuousIngest.genLong(env.getRowMin(), env.getRowMax(), r);
              endRow = endRow & suffixMask | startRow & prefixMask;

              while (endRow <= startRow) {
                endRow = ContinuousIngest.genLong(env.getRowMin(), env.getRowMax(), r);
                endRow = endRow & suffixMask | startRow & prefixMask;
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

              log.trace("SCN {} {} {} {} {}", t1, new String(scanStart, UTF_8), new String(scanStop, UTF_8), (t2 - t1), count);

              times.put(new QueryResult(t2-t1, count));

              if (scannerSleepMs > 0) {
                sleepUninterruptibly(scannerSleepMs, TimeUnit.MILLISECONDS);
              }
            }
          }catch (Exception e) {
            throw new RuntimeException(e);
          }
        };

        futures.add(executor.submit(runnable));
      }

      long waitTime = Math.max(1, 10000 / threads);

      while(true) {
        boolean allDone = true;
        for (Future<?> future : futures){
          try {
            future.get(waitTime, TimeUnit.MILLISECONDS);
          } catch (TimeoutException te) {
            //ignore
          }

          allDone &= future.isDone();
        }

        if(allDone)
          break;
      }


      var tss = timeSummaryStatistics;
      var rss = resultsSummaryStatistics;

      log.info("FINAL STATS count:{} minTime:{} maxTime:{} avgTime:{} stdevTime:{} minResults:{} maxResults:{} avgResults:{} stddevResults:{}",
      tss.getN(), tss.getMin(), tss.getMax(), tss.getMean(), tss.getStandardDeviation(),
      rss.getMin(), rss.getMax(), rss.getMean(), rss.getStandardDeviation());
    }
  }

}
